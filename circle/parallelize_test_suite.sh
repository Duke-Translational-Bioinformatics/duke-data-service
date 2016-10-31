#!/bin/bash

case $CIRCLE_NODE_INDEX in
  0)
    bundle exec rspec spec/[m]*
    ;;
  1)
    bundle exec rspec spec/[p]*
    ;;
  2)
    bundle exec rspec spec/[r]*
    ;;
  4)
    bundle exec rspec spec/[^mpr]*
    ;;
esac
