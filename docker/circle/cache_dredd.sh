#!/bin/bash

docker images dukedataservice_dredd | grep dukedataservice_dredd
if [ $? -gt 0 ]
then
  if [ ! -e docker/circle/dredd.docker.tgz ]
  then
    echo "building and caching dredd" >&2
    docker-compose build dredd
    docker save dukedataservice_dredd | gzip > docker/circle/dredd.docker.tgz
  fi
  echo "loading cached dredd" >&2
  docker load -i docker/circle/dredd.docker.tgz
fi
echo "dredd installed" >&2
