#!/bin/sh
# This is a wrapper for bundle_update.rb designed to run in a containerized
# environment where the user does not exist in the default /etc/passwd
# It will fail if the user does not have write access to /etc/passwd
# so you must ensure that the image has been created such that
# the default user group has rw access to /etc/passwd
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi
bundle exec bin/bundle_update.rb
