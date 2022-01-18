FROM postgres:13.3
MAINTAINER Darin London <darin.london@duke.edu>
RUN ["/usr/sbin/usermod", "-G", "postgres,staff", "postgres"]
ADD docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
