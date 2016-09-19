#!/bin/bash

if [ -s swift.env ]
then
  export COMPOSE_FILE='docker-compose.yml:docker-compose.dev.yml:docker-compose.swift.yml'
  docker-compose up -d swift
fi
docker-compose up -d neo4j elasticsearch
sleep 5
docker-compose up -d server
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run authservice
docker-compose run rake storage_provider:create
docker-compose run rake elasticsearch:index:create
