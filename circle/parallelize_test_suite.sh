#!/bin/bash

case $CIRCLE_NODE_INDEX in
  0)
    bundle exec rspec --format RspecJunitFormatter --out $CIRCLE_TEST_REPORTS/rspec.xml spec/models spec/serializers spec/policies spec/lib
    ;;
  1)
    bundle exec rspec --format RspecJunitFormatter --out $CIRCLE_TEST_REPORTS/rspec.xml spec/controllers spec/requests
    ;;
  2)
    ./circle/run_dredd.circle.sh
    ;;
esac
