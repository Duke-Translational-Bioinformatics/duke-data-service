#!/bin/bash

docker-compose up -d server
sleep 5
docker-compose ps
curl http://swift.circle.host:12345/info
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run authservice
docker-compose run rake storage_provider:create
