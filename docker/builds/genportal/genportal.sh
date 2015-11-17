#!/bin/bash

npm install
gulp build --type production
# if [ $? -gt 0 ]
# then
#   echo "PROBLEM"
#   exit 1
# fi
# cp -r /var/www/duke-data-service-portal/dist/* /var/www/app/portal
# echo "Generated"
# exit
