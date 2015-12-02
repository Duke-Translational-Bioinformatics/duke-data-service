FROM centos:latest
MAINTAINER Darin London <darin.london@duke.edu>

RUN ["/usr/bin/yum", "clean", "all"]
RUN ["/usr/bin/yum", "distro-sync", "-q", "-y", "--nogpgcheck"]
RUN ["/usr/bin/yum", "update", "-q", "-y","--nogpgcheck"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "gcc","gcc-c++", "glibc-static", "which", "zlib-devel", "readline-devel", "libcurl-devel", "tar"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "openssl", "openssl-devel"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "unzip", "bzip2", "wget"]
#shellshocked!
RUN ["/usr/bin/yum", "update", "-y", "--nogpgcheck", "bash"]
RUN ["mkdir", "-p", "/root/installs"]
WORKDIR /root/installs

#Ruby from source
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "libyaml", "libyaml-devel"]
ENV LATEST_RUBY ruby-2.2.2
ENV LATEST_RUBY_URL http://cache.ruby-lang.org/pub/ruby/2.2/${LATEST_RUBY}.tar.gz
ADD docker/includes/install_ruby.sh /root/installs/install_ruby.sh
RUN ["chmod", "777", "/root/installs/install_ruby.sh"]
RUN ["/root/installs/install_ruby.sh"]
RUN ["/usr/local/bin/gem", "install", "bundler"]

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

# user or deployments
RUN ["/usr/sbin/userdel", "ftp"]
RUN ["/usr/sbin/groupadd", "-g", "50", "staff"]
RUN ["/usr/sbin/useradd", "-N", "-u", "1000", "-g", "50", "deployer"]

#Postgresql client
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "postgresql","postgresql-devel"]

#miscellaneous
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "epel-release"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "git", "libxml2", "libxml2-devel", "libxslt", "libxslt-devel"]
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
