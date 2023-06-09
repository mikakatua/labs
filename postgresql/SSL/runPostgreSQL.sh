docker run -d --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v $PWD/server.crt:/var/lib/postgresql/certs/server.crt \
  -v $PWD/server.key:/var/lib/postgresql/certs/server.key \
  -v $PWD/root.crt:/var/lib/postgresql/certs/root.crt \
  -v $PWD/pg_hba.conf:/var/lib/postgresql/pg_hba.conf \
  -v $PWD/create_db.sql:/docker-entrypoint-initdb.d/create_db.sql \
  -p 5432:5432 \
  postgres:15.2 -c ssl=on -c ssl_cert_file=/var/lib/postgresql/certs/server.crt -c ssl_key_file=/var/lib/postgresql/certs/server.key -c ssl_ca_file=/var/lib/postgresql/certs/root.crt -c hba_file=/var/lib/postgresql/pg_hba.conf
