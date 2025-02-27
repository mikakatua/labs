# Docker-compose multi-node installation:
# https://github.com/elastic/elasticsearch/blob/master/docs/reference/setup/install/docker/docker-compose.yml

ELASTIC_PASSWORD=3cQLamPk0Hrh
KIBANA_PASSWORD=dhQyDQb2ouS3

mkdir -p certs/{es01,ca} esdata01 kibanadata

openssl genrsa -out certs/ca/ca.key 4096
openssl req -new -x509 -days 365 -key certs/ca/ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out certs/ca/ca.crt

openssl req -newkey rsa:4096 -nodes -keyout certs/es01/es01.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=es01.localnet" -out certs/es01/es01.csr

openssl x509 -req -extfile <(printf "subjectAltName=DNS:es01.localnet,DNS:elasticsearch.localnet") -days 365 -in certs/es01/es01.csr -CA certs/ca/ca.crt -CAkey certs/ca/ca.key -CAcreateserial -out certs/es01/es01.crt

sudo chown -R 1000:0 certs esdata01 kibanadata

docker network create elastic

# Start Elasticsearch node
docker run -d --name es-node01 --net elastic \
  -p 9200:9200 -p 9300:9300 \
  -e ES_JAVA_OPTS="-Xms1g -Xmx1g" \
  -e node.name=es01.localnet \
`#  -e cluster.name=docker-cluster` \
`#  -e cluster.initial_master_nodes=es01,es02,es03` \
`#  -e discovery.seed_hosts=es02,es03` \
  -e discovery.type=single-node \
  -e ELASTIC_PASSWORD=${ELASTIC_PASSWORD} \
  -e bootstrap.memory_lock=true \
  -e xpack.security.enabled=true \
  -e xpack.security.http.ssl.enabled=true \
  -e xpack.security.http.ssl.key=certs/es01/es01.key \
  -e xpack.security.http.ssl.certificate=certs/es01/es01.crt \
  -e xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt \
  -e xpack.security.http.ssl.verification_mode=certificate \
  -e xpack.security.transport.ssl.enabled=true \
  -e xpack.security.transport.ssl.key=certs/es01/es01.key \
  -e xpack.security.transport.ssl.certificate=certs/es01/es01.crt \
  -e xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt \
  -e xpack.security.transport.ssl.verification_mode=certificate \
  -e xpack.license.self_generated.type=basic \
  -v $PWD/certs:/usr/share/elasticsearch/config/certs \
  -v $PWD/esdata01:/usr/share/elasticsearch/data \
  --ulimit nofile=65535:65535 --ulimit memlock=-1:-1 \
  docker.elastic.co/elasticsearch/elasticsearch:8.0.0

# Check Elasticsearch is ready
curl --cacert certs/ca/ca.crt -u elastic:$ELASTIC_PASSWORD https://elasticsearch.localnet:9200

# Set kibana_system password
curl -X POST --cacert certs/ca/ca.crt -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json" https://elasticsearch.localnet:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}"

# Reset the password for the elastic user:
# docker exec -it es-node01 /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic

# Generate a new enrollment token for Kibana:
# docker exec -it es-node01 /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana

# Start Kibana node
docker run -d --name kib-01 --net elastic \
  -p 5601:5601 \
  -e SERVERNAME=kibana.localnet \
  -e SERVER_PUBLICBASEURL=http://kibana.localnet:5610 \
  -e ELASTICSEARCH_HOSTS='["https://es01.localnet:9200"]' \
  -e ELASTICSEARCH_USERNAME=kibana_system \
  -e ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD} \
  -e ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt \
  -v $PWD/certs:/usr/share/kibana/config/certs \
  -v $PWD/kibanadata:/usr/share/kibana/data \
  docker.elastic.co/kibana/kibana:8.0.0

# Access kibana and login with the 'elastic' user and password
# http://kibana.localnet:5601/
