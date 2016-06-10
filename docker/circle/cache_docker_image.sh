#!/bin/bash
image=$1
version=$2
docker_image="${image}:${version}"
docker_image_cache="docker/circle/${image}.${version}.docker.tgz"
docker images ${docker_image} | grep ${image}
if [ $? -gt 0 ]
then
  if [ ! -e ${docker_image_cache} ]
  then
    echo "pulling and caching ${docker_image}" >&2
    docker pull ${docker_image}
    docker save ${docker_image} | gzip > ${docker_image_cache}
  fi
  echo "loading cached ${docker_image}" >&2
  docker load -i ${docker_image_cache}
fi
echo "${docker_image} installed" >&2
