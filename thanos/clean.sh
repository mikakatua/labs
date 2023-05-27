docker rm -f prometheus-0-eu1 prometheus-0-eu1-sidecar minio store-gateway querier compact
docker network rm thanos
sudo rm -rf prom-eu1 minio
