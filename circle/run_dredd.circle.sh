#!/bin/bash

# cache necessary images
./docker/circle/cache_docker_image.sh ruby 2.6.3
./docker/circle/cache_docker_image.sh postgres 9.4
./docker/circle/cache_docker_image.sh ubuntu 14.04
./docker/circle/cache_dredd.sh
./docker/circle/cache_docker_image.sh morrisjobke/docker-swift-onlyone latest

# launch_application
docker-compose up -d server
sleep 10
docker-compose ps
curl http://swift.local:12345/info
docker-compose run rake db:migrate > /dev/null 2>&1
docker-compose run rake neo4j:migrate > /dev/null 2>&1
docker-compose run rake db:seed > /dev/null 2>&1
docker-compose run authservice > /dev/null 2>&1
docker-compose run rake storage_provider:create > /dev/null 2>&1
docker-compose run rake api_test_user:create > /dev/null 2>&1
docker-compose run rake api_test_user_pool:create > /dev/null 2>&1
docker-compose run rake elasticsearch:index:create
MY_GENERATED_JWT=$(docker-compose run rake api_test_user:create | tail -1)
HOST_NAME="http://dds.host:3000/api/v1"

# run dredd
docker-compose run -e "MY_GENERATED_JWT=${MY_GENERATED_JWT}" -e "HOST_NAME=${HOST_NAME}" dredd
