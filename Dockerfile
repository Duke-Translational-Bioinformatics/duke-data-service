FROM ruby:2.2.2
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

#miscellaneous
RUN ["mkdir","-p","/var/www/app"]
WORKDIR /var/www/app
RUN curl -L https://api.github.com/repos/Duke-Translational-Bioinformatics/duke-data-service/tarball/develop | tar -zxvf - --strip 1
ADD Gemfile /var/www/app/Gemfile
ADD Gemfile.lock /var/www/app/Gemfile.lock
RUN ["bundle", "config", "build.nokogiri", "--use-system-libraries"]
RUN ["bundle", "install"]

# run the app by defualt
EXPOSE 3000
CMD ["puma"]
