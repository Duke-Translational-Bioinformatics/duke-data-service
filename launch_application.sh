#!/bin/bash

if [ -s swift.env ]
then
  docker_compose_flags='-f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml'
  docker-compose ${docker_compose_flags} up -d swift
else
  docker_compose_flags='-f docker-compose.yml -f docker-compose.dev.yml'
fi
docker-compose up -d neo4j
sleep 5
docker-compose ${docker_compose_flags} up -d server
docker-compose ${docker_compose_flags} run rake db:migrate
docker-compose ${docker_compose_flags} run rake db:seed
docker-compose ${docker_compose_flags} run authservice
docker-compose ${docker_compose_flags} run rake storage_provider:create
