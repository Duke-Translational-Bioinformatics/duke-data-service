#!/bin/bash

docker images ruby:2.3.6 | grep ruby
if [ $? -gt 0 ]
then
  if [ ! -e docker/circle/ruby_2.3.6.docker.tgz ]
  then
    echo "pulling and caching ruby:2.3.6" >&2
    docker pull ruby:2.3.6
    docker save ruby:2.3.6 | gzip > docker/circle/ruby_2.3.6.docker.tgz
  fi
  echo "loading cached ruby:2.3.6" >&2
  docker load -i docker/circle/ruby_2.3.6.docker.tgz
fi
echo "ruby:2.3.6 installed" >&2
