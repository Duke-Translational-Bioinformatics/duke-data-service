#!/bin/bash

ruby_image=$(grep FROM Dockerfile | cut -d' ' -f2)
tarfile="$(echo $ruby_image | sed 's/\:/_/g').tgz"
docker images "${ruby_image}" | grep ruby
if [ $? -gt 0 ]
then
  if [ ! -e docker/circle/${tarfile} ]
  then
    echo "pulling and caching ${ruby_image}" >&2
    docker pull ${ruby_image}
    docker save ${ruby_image} | gzip > docker/circle/${tarfile}
  fi
  echo "loading cached ${ruby_image}" >&2
  docker load -i docker/circle/${tarfile}
fi
echo "${ruby_image} installed" >&2
