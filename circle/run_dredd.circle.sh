#!/bin/bash

docker-compose up -d server
sleep 10
docker-compose ps
curl http://swift.circle.host:12345/info
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run authservice
docker-compose run rake storage_provider:create
docker-compose run rake api_test_user:create
docker-compose run rake api_test_user_pool:create
echo "MY_GENERATED_JWT="`docker-compose run rake api_test_user:create | tail -1` >> dredd.env
docker-compose run dredd
