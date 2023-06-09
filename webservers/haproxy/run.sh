docker network create haproxy
docker rm -f web-1
docker run -d --rm --name web-1 -p 8080:80 --net haproxy -v $PWD/htdocs:/var/www/html php:apache
docker rm -f proxy
docker run -d --rm --name proxy -p 80:80 -p 443:443 --net haproxy \
  -v $PWD/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  -v $PWD/mydomain-wildcard.pem:/etc/haproxy/certs/keycloak.pem \
haproxy

