#!/bin/bash

if [ -z $COMPOSE_FILE ]
then
  docker-compose up -d server
  docker-compose -f dc-dev.utils.yml run rake db:migrate
  docker-compose -f dc-dev.utils.yml run rake db:seed
  docker-compose -f dc-dev.utils.yml run authservice
  if [ -s swift.env ]
  then
    docker-compose up -d swift
  fi
  docker-compose -f dc-dev.utils.yml run rake storage_provider:create
else
  docker-compose up -d server
  docker-compose run rake db:migrate
  docker-compose run rake db:seed
  docker-compose run authservice
  if [ -s swift.env ]
  then
    docker-compose up -d swift
  fi
  docker-compose run rake storage_provider:create
fi
