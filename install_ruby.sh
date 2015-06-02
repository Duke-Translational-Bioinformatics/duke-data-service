#!/bin/bash

cd /root/installs
wget ${LATEST_RUBY_URL}
tar -zxf ${LATEST_RUBY}.tar.gz
cd /root/installs/${LATEST_RUBY}
./configure --prefix=/usr/local --enable-shared --disable-install-doc
make
make install
cd /root/installs/${LATEST_RUBY}/ext/readline
/usr/local/bin/ruby extconf.rb
make
make install
cd /root/installs/${LATEST_RUBY}/ext/zlib
/usr/local/bin/ruby extconf.rb
make
make install
cd /root/installs/${LATEST_RUBY}/ext/openssl
export top_srcdir=/root/installs/${LATEST_RUBY}
make
make install
cd /root
rm -rf /root/installs/${LATEST_RUBY}
rm /root/installs/${LATEST_RUBY}.tar.gz
