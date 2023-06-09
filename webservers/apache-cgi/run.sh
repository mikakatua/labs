docker run -d --name webserver --net haproxy \
  -v $PWD/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf \
  -v $PWD/cgi-bin:/usr/local/apache2/cgi-bin \
httpd:2.4
