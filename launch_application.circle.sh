#!/bin/bash

docker-compose up -d swift
sleep 5
docker-compose ps
curl http://swift.circle.host:12345/info
docker-compose up -d server
echo "SLEEPING"
sleep 10
docker-compose ps
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run authservice
docker-compose run rake storage_provider:create
