#!/bin/bash

cd /var/www
git clone https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal.git
cd /var/www/duke-data-service-portal
npm install react-cookie
npm install
gulp build --type production
mv dist/index.html /var/www/app/portal/index.erb
rsync -avz dist/ /var/www/app/portal/
echo "Generated"
exit
