#!/bin/bash

docker-compose up -d swift
sleep 5
docker-compose ps
curl http:0.0.0.0:12345/info
docker-compose up -d server
sleep 5
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run authservice
docker-compose run rake storage_provider:create
