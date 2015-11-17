#!/bin/bash

npm install react-cookie
npm install
gulp build --type production
if [ $? -gt 0 ]
then
  echo "PROBLEM"
  exit 1
fi
rsync -avz dist/ /var/www/app/portal/
echo "Generated"
exit
