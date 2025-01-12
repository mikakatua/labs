# The ADOT Operator requires cert-manager to generate a self-signed certificate for the admission webhooks
module "cert_manager_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_cert_manager = true
  cert_manager = {
    chart_version = var.module_inputs.cert_manager_chart_version
    wait = true
  }

  tags = var.module_inputs.tags
}

resource "helm_release" "opentelemetry_operator" {
  name             = "opentelemetry"
  namespace        = "opentelemetry-operator-system"
  create_namespace = true
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-operator"
  version          = var.module_inputs.opentelemetry_operator_chart_version
  wait             = true

  set {
    name  = "manager.collectorImage.repository"
    value = "otel/opentelemetry-collector-k8s"
  }
  depends_on = [
    module.cert_manager_addon
  ]
}

resource "aws_prometheus_workspace" "amp" {
  alias = var.module_inputs.cluster_name

  tags = var.module_inputs.tags
}

# Role to allow OpenTelemetry collector send metrics to AMP
module "iam_assumable_role_adot" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.44.0"

  create_role  = true
  role_name    = "${var.module_inputs.cluster_name}-adot-collector"
  provider_url = var.module_inputs.cluster_oidc_issuer_url
  role_policy_arns = [
    "arn:${var.module_inputs.partition}:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector"]

  tags = var.module_inputs.tags
}

resource "helm_release" "grafana" {
  name             = "grafana"
  namespace        = "grafana"
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.module_inputs.grafana_chart_version

  values = [local.grafana_values]
  depends_on = [
    module.iam_assumable_role_grafana
  ]
}

# Role to allow Grafana query AMP metrics
module "iam_assumable_role_grafana" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.44.0"

  create_role  = true
  role_name    = "${var.module_inputs.cluster_name}-grafana"
  provider_url = var.module_inputs.cluster_oidc_issuer_url
  role_policy_arns = [
    "arn:${var.module_inputs.partition}:iam::aws:policy/AmazonPrometheusQueryAccess"
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:grafana:grafana"]

  tags = var.module_inputs.tags
}

resource "kubernetes_config_map" "order_service_metrics_dashboard" {
  metadata {
    name      = "order-service-metrics-dashboard"
    namespace = "grafana"
    annotations = {
      grafana_folder: "retail-app-metrics"
    }

    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "order-service-metrics-dashboard.json" = <<EOF
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            }
          },
          "mappings": []
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 9,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "pieType": "pie",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "builder",
          "expr": "sum by(productId) (watch_orders_total{productId!=\"*\"})",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Orders by Product ",
      "type": "piechart"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 6,
        "x": 9,
        "y": 0
      },
      "id": 6,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.2.2",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "code",
          "expr": "sum(watch_orders_total{productId=\"*\"}) by (productId)",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Order Count",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 15,
        "x": 0,
        "y": 9
      },
      "id": 4,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "code",
          "expr": "sum by (productId)(rate(watch_orders_total{productId=\"*\"}[2m]))",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Order Rate",
      "type": "timeseries"
    }
  ],
  "schemaVersion": 37,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-3h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Order Service Metrics",
  "uid": "r7QHEZEVz",
  "version": 1,
  "weekStart": ""
}
EOF
  }
  depends_on = [
    helm_release.grafana
  ]
}

locals {
  grafana_values = <<EOF
    # adminPassword: admin

    serviceAccount:
      create: true
      name: grafana
      annotations:
        eks.amazonaws.com/role-arn: "${module.iam_assumable_role_grafana.iam_role_arn}"

    env:
      AWS_SDK_LOAD_CONFIG: true
      GF_AUTH_SIGV4_AUTH_ENABLED: true

    ingress:
      enabled: true
      hosts: []
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
      ingressClassName: alb

    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
        - name: Prometheus
          type: prometheus
          url: "${aws_prometheus_workspace.amp.prometheus_endpoint}"
          access: proxy
          jsonData:
            httpMethod: "POST"
            sigV4Auth: true
            sigV4AuthType: "default"
            sigV4Region: ${var.module_inputs.region}
          isDefault: true

    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
        - name: default
          orgId: 1
          folder: ""
          type: file
          disableDeletion: false
          editable: false
          options:
            path: /var/lib/grafana/dashboards/default

    dashboards:
      default:
        kubernetesCluster:
          gnetId: 3119
          revision: 2
          datasource: Prometheus

    sidecar:
      dashboards:
        enabled: true
        searchNamespace: ALL
        label: grafana_dashboard
        folderAnnotation: grafana_folder
        provider:
          allowUiUpdates: true
          foldersFromFilesStructure: true
  EOF
}
