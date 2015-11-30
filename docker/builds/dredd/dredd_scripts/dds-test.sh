#!/bin/bash

#Auth run
dredd apiary.apib ${HOST_NAME} \
--header "Accept: application/json" \
--header "Authorization: ${MY_GENERATED_JWT}" \
--hookfiles "hooks.js"
# --only "Authorization Roles > Authorization Roles collection > List roles" \
# --only "Authorization Roles > Authorization Role instance > View role"
