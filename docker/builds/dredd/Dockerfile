FROM ubuntu:16.04

# install node.js and npm
RUN apt-get -qq update && apt-get install -y \
  nodejs \
  npm \
  git \
  python-pip \
  vim

#We've submitted 2 pull requests, until those are merged, we'll pull our own code in
RUN pip install dredd_hooks
RUN git clone https://github.com/benneely/dds.git
RUN cd /dds && python setup.py install

#Symlink
RUN ln -s /usr/bin/nodejs /usr/bin/node

# install dredd version older
RUN npm install -g try-thread-sleep dredd@1.0.8
RUN npm install try-thread-sleep dredd@1.0.8 node-promise node-rest-client

#Execute the node app
WORKDIR /home/dredd_scripts
CMD ["node","dds-dredd.js"]
