#!/bin/bash

docker-compose up -d server
sleep 10
docker-compose ps
curl http://swift.circle.host:8080/info
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run authservice
docker-compose run rake storage_provider:create
echo "MY_GENERATED_JWT="`docker-compose run rake api_test_user:create | tail -1` >> dredd.env
cat dredd.env
