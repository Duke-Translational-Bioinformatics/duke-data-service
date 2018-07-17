#!/bin/bash

app_var_name=$(echo "${CIRCLE_BRANCH}_HEROKU_APP_NAME" | tr "[:lower:]" "[:upper:]")

if [ -z "${!app_var_name}" ]
then
  echo "The variable ${app_var_name} is not set." >&2
  echo "Follow these instructions to set the project-level environment variable:" >&2
  echo "https://circleci.com/docs/2.0/env-vars/#adding-project-level-environment-variables" >&2
  exit 1
fi

echo "${!app_var_name}"
