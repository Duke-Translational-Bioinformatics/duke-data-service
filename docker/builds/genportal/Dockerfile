FROM node:0.12

RUN ["npm", "install", "--global", "gulp"]
ADD genportal.sh /usr/local/bin/genportal.sh
RUN ["chmod", "+x", "/usr/local/bin/genportal.sh"]
WORKDIR /var/www
RUN ["git", "clone", "https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal.git"]
WORKDIR /var/www/duke-data-service-portal
