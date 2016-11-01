#!/bin/bash

case $CIRCLE_NODE_INDEX in
  0)
    bundle exec rspec
    ;;
  1)
    ./circle/run_dredd.circle.sh
    ;;
esac
