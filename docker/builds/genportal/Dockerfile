FROM node:0.12

RUN apt-get update && apt-get install -y --no-install-recommends rsync
RUN ["npm", "install", "--global", "gulp"]
ADD genportal.sh /usr/local/bin/genportal.sh
RUN ["chmod", "+x", "/usr/local/bin/genportal.sh"]
WORKDIR /var/www/duke-data-service-portal
CMD /usr/local/bin/genportal.sh
