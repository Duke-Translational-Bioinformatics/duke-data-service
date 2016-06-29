#!/bin/bash

# cache necessary images
./docker/circle/cache_docker_image.sh ruby 2.2.2
./docker/circle/cache_docker_image.sh postgres 9.4
./docker/circle/cache_docker_image.sh ubuntu 14.04
./docker/circle/cache_dredd.sh
./docker/circle/cache_docker_image.sh morrisjobke/docker-swift-onlyone latest

# launch_application
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

# run dredd
docker-compose run dredd
