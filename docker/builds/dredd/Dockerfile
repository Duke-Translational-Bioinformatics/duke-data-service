FROM ubuntu:14.04

# install node.js and npm
RUN apt-get -qq update && apt-get install -y \
  nodejs \
  npm \
  curl

#Symlink
RUN ln -s /usr/bin/nodejs /usr/bin/node

# install dredd
RUN npm install -g dredd@1.0.8

#install node modules
RUN npm install hooks
RUN npm install shortid32
RUN npm install underscore
RUN npm install node-rest-client
RUN npm install node-promise
RUN npm install fs
RUN npm install md5
RUN npm install dredd

#COPY Files
#These files are now mounted via docker-compose.circle.yml
#COPY ./dredd_scripts /home/dredd_scripts/

#Execute the node app
WORKDIR /home/dredd_scripts
CMD ["node","dds-dredd.js"]
