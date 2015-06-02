#!/bin/bash
mkdir -p /etc/pki/tls /etc/pki/tls/private /etc/pki/tls/certs
/usr/bin/openssl req -nodes -newkey rsa:2048 -keyout /etc/pki/tls/private/localhost.key -config /root/installs/cert_config -out /etc/pki/tls/certs/localhost.csr
/usr/bin/openssl x509 -req -days 36500 -in /etc/pki/tls/certs/localhost.csr -signkey /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt
