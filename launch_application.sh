#!/bin/bash

if [ -z $COMPOSE_FILE ]
then
  docker-compose up -d
  docker-compose -f dc-dev.utils.yml run rake db:migrate
  docker-compose -f dc-dev.utils.yml run authservice
else
  docker-compose up -d server
  docker-compose run rake db:migrate
  docker-compose run rake db:seed
  docker-compose run authservice
fi
