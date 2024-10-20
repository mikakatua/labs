#!/bin/sh

CONTAINER_NAME=mypostgres

if [ -n "$(docker ps -a --filter name=$CONTAINER_NAME --filter status=exited | grep -w $CONTAINER_NAME)" ]; then
  echo "Starting postgres instance ..."
  docker start $CONTAINER_NAME
elif [ -n "$(docker ps -a --filter name=$CONTAINER_NAME --filter status=running | grep -w $CONTAINER_NAME)" ]; then
  echo "Postgres instance still running"
else
  echo "Creating postgres instance ..."
  docker run -d --name $CONTAINER_NAME\
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=mysecretpassword \
  --env-file db.env \
  -v $PWD/init-db/:/docker-entrypoint-initdb.d/ \
  postgres:16.4
fi
