#!/bin/bash

docker images neo4j:latest | grep ruby
if [ $? -gt 0 ]
then
  if [ ! -e docker/circle/neo4j_latest.docker.tgz ]
  then
    echo "pulling and caching neo4j:latest" >&2
    docker pull neo4j:latest
    docker save neo4j:latest | gzip > docker/circle/neo4j_latest.docker.tgz
  fi
  echo "loading cached neo4j:latest" >&2
  docker load -i docker/circle/neo4j_latest.docker.tgz
fi
echo "neo4j:latest installed" >&2
