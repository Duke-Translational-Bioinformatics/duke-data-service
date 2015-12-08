#!/bin/bash

docker images ruby:2.2.2 | grep ruby
if [ $? -gt 0 ]
then
  if [ ! -e docker/circle/ruby_2.2.2.docker.tgz ]
  then
    docker pull ruby:2.2.2
    docker save ruby:2.2.2 | gzip > docker/circle/ruby_2.2.2.docker.tgz
  fi
  docker load -i docker/circle/ruby_2.2.2.docker.tgz
fi
