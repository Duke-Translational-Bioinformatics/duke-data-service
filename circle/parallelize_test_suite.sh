#!/bin/bash

case $CIRCLE_NODE_INDEX in
  0)
    bundle exec rspec --format RspecJunitFormatter --out $CIRCLE_TEST_REPORTS/rspec.xml
    ;;
  1)
    ./circle/run_dredd.circle.sh
    ;;
esac
