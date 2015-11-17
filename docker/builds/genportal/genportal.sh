#!/bin/bash

npm install react-cookie
npm install
gulp build --type production
mv dist/index.html /var/www/app/portal/index.html
rsync -avz dist/ /var/www/app/public/
echo "Generated"
exit
