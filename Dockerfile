FROM ruby:2.3.6
MAINTAINER Darin London <darin.london@duke.edu>

RUN ["mkdir", "-p", "/root/installs"]
WORKDIR /root/installs

# Node binary
ENV LATEST_NODE node-v0.12.7-linux-x64
ENV LATEST_NODE_URL https://nodejs.org/dist/v0.12.7/node-v0.12.7-linux-x64.tar.gz
ADD docker/includes/install_node.sh /root/installs/install_node.sh
RUN ["chmod", "777", "/root/installs/install_node.sh"]
RUN ["/root/installs/install_node.sh"]
RUN ["npm","install","-g","bower"]

# ssl certs
ADD docker/includes/install_ssl_cert.sh /root/installs/install_ssl_cert.sh
ADD docker/includes/cert_config /root/installs/cert_config
RUN ["chmod", "u+x", "/root/installs/install_ssl_cert.sh"]
RUN ["/root/installs/install_ssl_cert.sh"]

#Postgresql client
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y postgresql libpq-dev

#GraphViz for Rails ERD
RUN /usr/bin/apt-get install -y graphviz

#RubyGems system update
RUN ["gem", "update", "--system", "2.7.6"]

#miscellaneous
RUN ["mkdir","-p","/var/www"]
WORKDIR /var/www
RUN git clone https://github.com/Duke-Translational-Bioinformatics/duke-data-service.git app
WORKDIR /var/www/app
RUN git checkout develop
ADD Gemfile /var/www/app/Gemfile
ADD Gemfile.lock /var/www/app/Gemfile.lock
RUN ["bundle", "config", "build.nokogiri", "--use-system-libraries"]
RUN ["bundle", "install", "--jobs=4"]

# run the app by defualt
EXPOSE 3000
CMD ["puma"]
