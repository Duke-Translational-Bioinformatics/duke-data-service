#!/bin/bash

docker images ruby:2.3.3 | grep ruby
if [ $? -gt 0 ]
then
  if [ ! -e docker/circle/ruby_2.3.3.docker.tgz ]
  then
    echo "pulling and caching ruby:2.3.3" >&2
    docker pull ruby:2.3.3
    docker save ruby:2.3.3 | gzip > docker/circle/ruby_2.3.3.docker.tgz
  fi
  echo "loading cached ruby:2.3.3" >&2
  docker load -i docker/circle/ruby_2.3.3.docker.tgz
fi
echo "ruby:2.3.3 installed" >&2
