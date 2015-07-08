Development with Docker
-----------------------
We use [Docker](https://www.docker.com/) to run, test, and debug our application. The following documents how to install and use
Docker on a Mac, either Mavericks or Yosemite. There are
[instructions](https://docs.docker.com/installation)
for installing and using docker on other operating systems.

On the mac, we use [docker-machine](https://docs.docker.com/machine/) and
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) to manage our
docker host on an Virtualbox VM using the standard Boot2docker docker host.
You may not need docker-machine if you use a modern Linux OS. It is also
possible to use docker-machine with VMWare Fusion, among other vm management
and even cloud hosting platforms.

We use [docker-compose](https://docs.docker.com/compose/) to automate most of
our interactions with the application.

Installation & Upgrade
------------
docker commandline:
```
sudo su -
curl -L https://get.docker.com/builds/Darwin/x86_64/docker-latest > /usr/local/bin/docker
chmod +x /usr/local/bin/docker
```

docker-machine:
```
sudo su -
curl -L https://github.com/docker/machine/releases/download/v0.2.0/docker-machine_darwin-amd64 > /usr/local/bin/docker-machine
chmod +x /usr/local/bin/docker-machine
```

docker-compose:
```
sudo su -
curl -L https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

If you do not have sudo, you may be able to install these in another directory
that is in your PATH.

Docker Machine Management
-------------------------

The docker-machine command is designed to create a docker-machine to run in a
variety of virtualization environments.
We use docker-machine to create a VirtualBox Virtual Machine from the official
Boot2docker image on our system. This VM image contains a fully configured
docker daemon, and automatically mounts the /User directory to the VM when it
starts. This makes it possible to host any directory within /User to docker
containers (running instances) as docker volumes. You should only need one
docker-machine on your system (although you can create and run multiple
docker-machines to simulate running different, isolated host machines if you are
working with more complicated application stacks, or microservices). You can
create a Virtualbox docker-machine with the following command:
```
docker-machine create --driver virtualbox dev
```
This will download a Virtualbox Boot2docker VM image, configure the TLS
certificates required for the docker command to communicate with the VM, and
launch the VM instance.  The machine it creates is called 'dev' (this is also
the name of the VM in the Virtualbox console), and this name should be used in
all docker-machine commands to refer to it specifically (docker-machine can be
run without a name argument, and it will use the 'Active' machine by default,
but this is not recommended if you create more than one docker-machine. If you
want to use a different name, substitute 'dev' with whatever name you want to
use in the create command above, and use that name in all docker-machine
commands).

If you want to stop the VM:
```
docker-machine stop dev
```

If you want to start a stopped VM:
```
docker-machine start dev
```

If you want to list the docker-machines that you have on your system, with their
status:
```
docker-machine ls
```

If you ever need to destroy your entire machine, including any docker images
downloaded or built:
```
docker machine rm dev
```

The docker command is designed to be wired to a docker machine daemon on any
machine using environment variables. The docker-machine command makes it easy to
set these in your shell.  To see what they are:
```
docker-machine env dev
```
Use the following single command to set these:
```
eval $(docker-machine env dev)
```

Use the following to find the ip of the Boot2docker VM on your machine. You will
use this in any URL to connect to running services on the docker machine:
```
docker-machine ip dev
```

Once you have a running docker-machine, and you have set the docker ENVIRONMENT,
you can run any of the following commands to test that your docker command is
wired to communicate with your docker machine:
```
docker ps
```
This should always return a table with the following headers, and 0 or more
entries:
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

```
docker images
```
Similar to above, it should always return a table with the following headers, and
0 or more entries:
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE

Dockerfile
-----------
Docker uses a [Dockerfile](https://docs.docker.com/reference/builder/) to
specify how to build an image to host an application. You should create a
Dockerfile in the Application Root. This should start from a base image
(typically an official linux base image such as centos, ubuntu, etc.), and
install only the libraries and applications needed to run your application. For
a typical rails application, this would include libraries such as openssl,
libxml, etc, the exact version of ruby, compiled from source, and a minimal
set of gems, such as bundler. By placing the Dockerfile in the Application Root,
you can ADD your Gemfile and Gemfile.lock to the machine and bundle install them
to add Application gems to the resulting image.

You should avoid installing daemon processes inside the application container.
For a rails application, you can serve it by specifying a CMD using rails s, etc.
instead of installing apache + passenger.  Here are some example CMD lines:
CMD ["rails", "s"]
CMD ["thin"]
CMD ["puma"]

If your rails application needs a support service, such as a postgres db, redis,
etc, you can host these as applications in their own Docker image, run both
the server and the support service as container instances, and link them together
at run time. For many opensource databases, there are even official Docker
registry hosted images available for you to download and use in your application
stack.  Docker-compose (see below) can be used to easily specify how to wire
these systems together.

If you absolutely need a daemon (such as with shibboleth and shibd), you should
ADD a bash script, maybe named run.sh, that specifies how to start the daemon and
your application, and specify a CMD to run run.sh.

Dockerfiles can have ADD commands which instruct docker to copy any file relative
to the directory containing the Dockerfile to the image to be used either during
the build, or after it is built. These files become a permanent part of the image
produced by the build. Our convention is to place any scripts, configuration,
etc. that are not part of the default application (e.g. for a rails application,
Gemfile, app, config, etc.) into the docker/includes directory, and ADD them
from this directory, e.g.:

ADD docker/includes/run.sh

This makes it easier to copy the docker directory to other projects.

Typically, your Dockerfile should have a default WORKDIR. For a rails application
this might look like:
WORKDIR /var/www/app

/var/www/app can point to a directory that actually exists in the image (e.g. by
creating it and ADDing files to it), but this is optional. In develop, you will
typically mount the Application Root from your workstation into the container
as a volume, so that you any files produced by running commands in the container
(e.g. rails g model, etc.) will be written into the actual directory on your
workstation, and any changes you make to the source will be reflected live in
the running server, just as if the server was running natively on your
workstation.

You should strive to include your Dockerfile or docker/includes
configurations/scripts in the source control repository for the application.
This forms the basis for sharing the exact compute environment for your
application with the rest of your team. Using docker, your teammates will
no longer need to install different versions of ruby, gems, databases, apache,
passenger, etc. on their work stations. Instead, the exact compute environments,
and support services required are hosted in docker.

There are many good examples of Dockerfiles available on the
[Docker Registry](https://registry.hub.docker.com/search?q=library).
You can open any of the official repositories to find good examples of
Dockerfiles. There are also good examples on github. Also, many of the ORIRAD
applications (CTTI, FRDS, Sparc) are dockerized.

Docker Compose
--------------
Once you have docker configured to talk to your docker-machine, you can use
docker-compose to automate building, and launching the application within a
docker machine. Docker Compose uses a yml file to specify everything required
to build and run the application and any other support application (databases,
volume containers, etc.) it requires.

By default, docker-compose looks for a file called 'docker-compose.yml' in the
directory where it is run, e.g. in the Application Root (with the Dockerfile).

By default, anyone with docker, docker-machine, and docker-compose can run the
following command from within the Application Root (where this file you are
reading resides), to build the server image and any other ancillary support
images that it needs (You must be connected to the internet so that docker can
pull down any base docker images, or package/gem installs, for this to work).
```
docker-compose build
```
Once you have built the image, you can launch containers of all services
required by the app (docker calls a running instance of a docker image a docker
container):
```
docker-compose up -d
```

The docker-compose for this application mounts the Application Root as
/var/www/app in the server docker container.  The Dockerfile specifies
/var/www/app as its default WORKDIR. It also hosts the application to port
3000 inside the container, which is attached to port 3001 on the docker-machine
VM host (this will fail if you have another service of any kind attached to port 3001).
To connect to this host, you should use the following docker-machine command to find
the ip of the docker-machine:
```
docker-machine ip dev
```
Then you can use curl, or your browser to connect to
http://$(docker-machine ip dev):3001 to interact with the running application.

To stop all running docker containers (you must stop a container before you can
remove it or its image):
```
docker-compose stop
```

When a docker container stops for any reason, docker keeps it around in its
system.  There are ways you can start and attach to a stopped container, but
in many cases this is not useful. You should remove containers on a
regular basis. Note, because we do not persist the data in our postgres databases
to the host file system, all of your databases are removed when you remove their
stopped containers. When you start up the machines from scratch, you will need
to run rake db:migrate, etc. to get the database ready.
You can list all running containers using the following command:
```
docker ps
```
You can list all containers (both running and stopped):
```
docker ps -a
```

Each docker container is given a long UUID by docker (called the CONTAINERID).  
You can use this UUID (or even the first 4 or more characters) to stop
and remove a container using the docker commandline instead of
using docker-compose (which abstracts the UUID from the user):
```
docker stop UUID
docker rm UUID
```

Sometimes docker will leave files from a container on the host, which can build
up over time and cause your VM to become sluggish or behave strangely.  We
recommend adding the -v (volumes) flag to docker rm commands to make sure these
files are cleaned up appropriately.  Also, docker ps allows you to pass the -q
flag, and get only the UUID of the containers it lists.  Using the following
command, you can easily stop all running containers:
```
docker stop $(docker ps -q)
```

Similarly, to remove all stopped commands (this will skip running commands, but
print a warning for each):
```
docker rm -v $(docker ps -aq)
```
(It is useful to alias this particular command in your bash_profile). We
recommend running this command frequently to clean up containers that build up
over time.

A second yaml file has been placed in the application root, dc-dev.utils.yml.  
This yaml file should have everything in the default docker-compose.yml or
extend it using the docker-compose extend syntax. It adds docker-compose 'services'
to make it possible to easily run things like rspec, rails,
rake, etc.

You can use this file in one of two ways.
* add the -f dc-dev.utils.yml flag to all of your docker-compose commands, e.g.
```
docker-compose -f dc-dev.utils.yml up -d server
docker-compose -f dc-dev.utils.yml run rails c
```

An easier way to do this is to set the following shell environment variable:
export COMPOSE_FILE=dc-dev.utils.yml
(it may be useful to do this in your bash_profile)

In either case, you should always specify the exact service (e.g. top level key
in the dc-dev.utils.yml file). Otherwise, docker-compose will try to run all
services in the background (including cap dev deploy).

Here is a list of docker-compose commands available using our dc-dev.utils.yml
(assume the COMPOSE_FILE environment as been set):

Launch the server and postgresdb to interact with the application:
```
docker-compose up -d server
```
Docker-compose is smart enough to realize all of the linked services required,
and spin them up in order.

Run the rspec (as RAILS_ENV=test)
```
docker-compose run rspec
docker-compose run rspec spec/requests
docker-compose run rspec spec/models/survey_spec.rb
```

Run bundle install (you will need to do this even if you
have built the application, or the Gemfile.lock file will
not get updated to reflect the newly installed gems.):
```
docker-compose run server bundle install
```

Run rake commands (default RAILS_ENV=development):
```
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run rake db:migrate RAILS_ENV=test
```

Run rails commands (default RAILS_ENV=development):
```
docker-compose run rails c
docker-compose run rails c RAILS_ENV=test
```

Create the AuthenticationService object that links to the
[DukeAuthenticationService](https://github.com/Duke-Translational-Bioinformatics/duke-authentication-service) container that is run from its Application Root using docker-compose
(see below):
```
docker-compose run authservice
```

Remove the authservice
```
docker-compose run authservice authservice:destroy
```

Connecting a DukeAuthenticationService microservice
--------------------------------------------------
The Duke Data Service application requires a Duke Authentication Service
microservice to provide authentication.  When you git clone the Duke Authentication
Service repo, it comes with its own docker-compose.yml and dc-dev.utils.yml
specifying standard ports to use to connect to it on the docker-machine.
An AuthenticationService object must be created in the Duke Data Service
container to register a Duke Authentication Service, and a Consumer object must
be created in the Duke Authentication Service container to register the Duke
Data Service.
Both this repo and the Duke Authentication Service repo come with rake tasks
to create these objects once their respective db services have been started.

Assuming you are starting from scratch (e.g. you do not have any db containers
running or stopped for this or the Authentication Service), you can get both
up and running and wired together with the following set of commands:

```
cd PATHTO/duke-authentication-service
docker-compose up -d rproxy
docker-compose run rake db:migrate
docker-compose run consumer
cd PATHTO/duke-data-service
docker-compose up -d server
docker-compose rake db:migrate
docker-compose run authservice
```

the above commands have been collected into shell scripts in the root of both.
You can accomplish the same as above (regardless of whether your COMPOSE_FILE
environment variable has been set) using:
```
cd PATHTO/duke-authentication-service
./launch_application.sh
cd PATHTO/duke-data-service
./launch_application.sh
```

Troubleshooting Docker
----------------------
If your docker command is not wired to communicate with your docker machine, or
your docker-machine is not running, docker-compose will return the following
response:
Couldn't connect to Docker daemon - you might need to run `boot2docker up`.

Do NOT run boot2docker up!  Docker machine takes care of this for you. Instead,
check the following:
1. Is your docker-machine running:
```
docker-machine ls
```

2. Is your docker ENVIRONMENT setup properly
```
eval $(docker-machine env dev)
```

In some cases, the docker-machine VM gets shut down with an invalid state,
which causes it to fail to restart when you run docker-machine start dev.
In this case, you should use the Virtualbox Application Interface to discard the
saved state of the machine (it is named 'dev' if you crated the docker-machine
with 'dev'). Right click on the machine in the left panel, and stop it if it is
not already stopped, then 'discard saved state'.

Bash Profile
------------
The following can be placed in the .bash_profile file located in your
HOME directory (e.g. ~/.bash_profile)

```bash_profile
# Docker configurations and helpers
export COMPOSE_FILE=dc-dev.utils.yml
alias docker_cleanup='docker rm -v $(docker ps -aq)'
alias docker_images_cleanup='docker rmi $(docker images -f dangling=true -q)'

# include these lines only if you have just one docker-machine
dm_env=$(docker-machine env)
echo "${dm_env}"
eval "${dm_env}"

```

Cisco VPN
---------

The Cisco Anyconnect VPN client can be configured by the VPN systems
administrators to reconfigure your host network
in ways the prevent your docker binary from communicating with the docker machine
VM. The symptom that you will notice if this is
the case is that calls to docker-compose, or docker will hang for a while, and
then timeout.  There are two things that you need to
do to restore your ability to work with docker while connected to a VPN using
Cisco Anyconnect VPN.

1. Remove any 'deny ip any from any' firewall rules that the VPN has placed into
your host firewall
2. Reconfigure the docker-machine ip to connect to the vboxnet network interface
instead of the utun0 network interface created by the VPN.

There is a [script](https://gist.github.com/dmann/f62f2dd17a02293121ed) that we
have written to automate this. You should download this and place it in
/usr/local/bin/fix_anyconnect.sh (as root or sudo).

```bash
sudo su -
curl https://gist.githubusercontent.com/dmann/f62f2dd17a02293121ed/raw/dbaccf0b867aecb999bc80f1d0b3e2741d6f74cd/vpn_fix.sh > /usr/local/bin/fix_anyconnect.sh
chmod +x /usr/local/bin/fix_anyconnect.sh
```

Anytime you need to connect to the VPN, you should run this BEFORE and AFTER
you connect to the VPN (also, make sure your docker-machine is running).
```
fix_anyconnect.sh
```

If you have more than one docker-machine defined on your system, you will need
to specify it by name:
```
fix_anyconnect.sh dev
```

By running the command before you connect to the VPN, you ensure that there is
an existing netstat route for the docker-machine ip connected to the vboxnet
network interface. Connecting to the VPN will then change this to connect
to the utun0 interface.  Running this command again will reconfigure the
docker-machine ip to connect to the vboxnet interface.
If you do not run this command before you connect to the VPN, and then run the
command after you connect, it will reconfigure all network traffic to connect to
the vboxnet interface, and you will lose your internet connections.
To fix this, disconnect from the VPN to restore your internet connectivity, then
you can run fix_anyconnect.sh connect and run fix_anyconnect.sh in sequence.
Also, if your internet connectivity bounces for any reason, and your VPN
anyconnect software has to reconnect, it will likely reconfigure your machine to
the wrong state again. You will need to disconnect from the VPN, run
fix_anyconnect.sh, reconnect to the VPN, and then run fix_anyconnect.sh. Finally
after you disconnect from Cisco Anyconnect VPN, you will need to run
fix_anyconnect.sh to restore any network changes made as the VPN Client exits.

*A further complication was introduced by the upgrade of Yosemite*.
In the Yosemite realease, the /sbin/ipfw command was removed! Yet, Cisco VPN can
still set up 'deny any from any' firewall rules. We have had success copying
/sbin/ipfw from a Mavericks mac to our Yosemite machine to restore the ability
of fix_anyconnect.sh to work.

It may also be possible to use the recommended apple firewall system to fix the
network.
