#!/bin/bash

cd /root/installs
wget ${LATEST_NODE_URL}
tar -zxf ${LATEST_NODE}.tar.gz
mv ${LATEST_NODE}/bin/node /usr/bin/node
mv ${LATEST_NODE}/bin/npm /usr/bin/npm
mv ${LATEST_NODE}/lib/node_modules /usr/lib/node_modules
rm -rf ${LATEST_NODE}
rm ${LATEST_NODE}.tar.gz
