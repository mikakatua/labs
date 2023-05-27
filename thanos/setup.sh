docker network create thanos

# Generate artificial data

mkdir prom-eu1 && docker run -i --rm quay.io/thanos/thanosbench:v0.3.0-rc.0 block plan -p continuous-365d-tiny --labels 'cluster="eu1"' --max-time=6h | docker run -i --rm -v $(pwd)/prom-eu1:/out quay.io/thanos/thanosbench:v0.3.0-rc.0 block gen --output.dir /out

# Prometheus
sudo chown -R 65534 prom-eu1 && \
docker run -d --net=thanos --rm \
    -p 9090:9090 \
    -v $(pwd)/prometheus0_eu1.yml:/etc/prometheus/prometheus.yml \
    -v $(pwd)/prom-eu1:/prometheus \
    --name prometheus-0-eu1 \
    quay.io/prometheus/prometheus:v2.43.0 \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.retention.time=1000d \
    --storage.tsdb.path=/prometheus \
    --storage.tsdb.max-block-duration=2h \
    --storage.tsdb.min-block-duration=2h \
    --web.listen-address=:9090 \
    --web.enable-lifecycle \
    --web.enable-admin-api

# Minio
mkdir -p minio/thanos && \
docker run -d --net=thanos --rm --name minio \
    -p 9001:9001 \
     -v $(pwd)/minio:/data \
     -e "MINIO_ROOT_USER=minio" -e "MINIO_ROOT_PASSWORD=melovethanos" \
     -e "MINIO_PROMETHEUS_AUTH_TYPE=public" \
     minio/minio:RELEASE.2023-03-24T21-41-23Z \
     server /data --console-address ":9001"

# Thanos Sidecar
docker run -d --net=thanos --rm \
    -v $(pwd)/bucket_storage.yaml:/etc/thanos/minio-bucket.yaml \
    -v $(pwd)/prometheus0_eu1.yml:/etc/prometheus/prometheus.yml \
    -v $(pwd)/prom-eu1:/prometheus \
    --name prometheus-0-eu1-sidecar \
    quay.io/thanos/thanos:v0.31.0 \
    sidecar \
    --tsdb.path /prometheus \
    --objstore.config-file /etc/thanos/minio-bucket.yaml \
    --shipper.upload-compacted \
    --http-address 0.0.0.0:19090 \
    --grpc-address 0.0.0.0:19190 \
    --reloader.config-file /etc/prometheus/prometheus.yml \
    --prometheus.url http://prometheus-0-eu1:9090

# Thanos Store Gateway
docker run -d --net=thanos --rm \
    -v $(pwd)/bucket_storage.yaml:/etc/thanos/minio-bucket.yaml \
    --name store-gateway \
    quay.io/thanos/thanos:v0.31.0 \
    store \
    --objstore.config-file /etc/thanos/minio-bucket.yaml \
    --http-address 0.0.0.0:19091 \
    --grpc-address 0.0.0.0:19191

# Thanos Querier
docker run -d --net=thanos --rm \
    -p 9091:9091 \
    --name querier \
    quay.io/thanos/thanos:v0.31.0 \
    query \
    --http-address 0.0.0.0:9091 \
    --query.replica-label replica \
    --store prometheus-0-eu1-sidecar:19190 \
    --store store-gateway:19191

# Thanos Compactor
docker run -d --net=thanos --rm \
    -p 19095:19095 \
    -v $(pwd)/bucket_storage.yaml:/etc/thanos/minio-bucket.yaml \
    --name compact \
    quay.io/thanos/thanos:v0.31.0 \
    compact \
    --wait --wait-interval 30s \
    --consistency-delay 0s \
    --objstore.config-file /etc/thanos/minio-bucket.yaml \
    --http-address 0.0.0.0:19095

