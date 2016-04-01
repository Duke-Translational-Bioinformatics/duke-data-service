Development with Docker
===
We use [Docker](https://www.docker.com/) to run, test, and debug our application.
The following documents how to install and use Docker on a Mac. There are
[instructions](https://docs.docker.com/installation) for installing and using
docker on other operating systems.

On the mac, we use [docker-machine](https://docs.docker.com/machine/) and
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) to manage our
docker host on an Virtualbox VM using the standard Boot2docker docker host.
You may not need docker-machine if you use a modern Linux OS. It is also
possible to use docker-machine with VMWare Fusion, among other vm management
and even cloud hosting platforms.

We use [docker-compose](https://docs.docker.com/compose/) to automate most of
our interactions with the application.

Table of Contents
===
* [Installation and Upgrade](#installation-and-upgrade)
* [Docker Machine Management](#docker-machine-management)
* [Launching the Application](#launching-the-application)
* [Docker Compose](#docker-compose)
* [Creating an API_TEST_USER and token](#creating-an-api_test_user-and-token)
* [Connecting to an Openstack Swift Object Store](#connecting-to-an-openstack-swift-object-store)
* [Running a local swift service using Docker](#running-a-local-swift-service-using-docker)
* [Running the Workflow](#running-the-workflow)
* [Run Dredd](#run-dredd)
* [The Api Explorer](#the-api-explorer)
* [The Portal](#the-portal)
* [Connecting a Duke Authentication Service microservice](#connecting-a-duke-authentication-service-microservice)
* [Dockerfile](#dockerfile)
* [Deploying Secrets](#deploying-secrets)
* [Troubleshooting Docker](#troubleshooting-docker)
* [Bash Profile](#bash-profile)
* [Cisco VPN](#cisco-vpn)

Installation and Upgrade
===

Docker makes it easy to install docker-machine, docker, and docker-compose
on your mac, and keep them upgraded in sync.  Follow the instructions
to install the [Docker Toolbox](https://www.docker.com/docker-toolbox).

Docker Machine Management
===

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
docker-machine create --driver virtualbox default
```
This will download a Virtualbox Boot2docker VM image, configure the TLS
certificates required for the docker command to communicate with the VM, and
launch the VM instance.  The machine it creates is called 'default' (this is also
the name of the VM in the Virtualbox console), and this name should be used in
all docker-machine commands to refer to it specifically.

If you want to stop the VM:
```
docker-machine stop default
```

If you want to start a stopped VM:
```
docker-machine start default
```

If you want to list the docker-machines that you have on your system, with their
status:
```
docker-machine ls
```

If you ever need to destroy your entire machine, including any docker images
downloaded or built:
```
docker-machine rm default
```

The docker command is designed to be wired to a docker machine daemon on any
machine using environment variables. The docker-machine command makes it easy to
set these in your shell.  To see what they are:
```
docker-machine env default
```
Use the following single command to set these:
```
eval $(docker-machine env default)
```

Use the following to find the ip of the Boot2docker VM on your machine. You will
use this in any URL to connect to running services on the docker machine:
```
docker-machine ip default
```

Once you have a running docker-machine, and you have set the docker ENVIRONMENT,
you can run any of the following commands to test that your docker command is
wired to communicate with your docker machine:
```
docker ps
```
This should always return a table with the following headers, and 0 or more
entries:

`CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES`

```
docker images
```
Similar to above, it should always return a table with the following headers, and
0 or more entries:

`REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE`

Launching the Application
===
This project includes a shell script, launch_application.sh, which will:

* bring up a running instance of the DDS server
* bring up a postgres DB instance
* optionally bring up a [local swift service](#running-a-local-swift-service-using-docker)
  if the swift.env file is not empty
* uses rake to:
  * migrate and seed the database
  * create an AuthService using auth_service.env
  * create a StorageProvider using swift.env (this may not do anything if swift.env
    is empty).

This script works either with the DOCKER_COMPOSE environment variable unset, or
set to the dc-dev.utils.yml file (see [Docker Compose](#docker-compose)).

**Use this script to launch the application**, and read on for how this
script works, and how you can utilize docker and docker-compose to develop and
test the system.

Docker Compose
===

Once you have docker configured to talk to your docker-machine, you can use
docker-compose to run all of the commands that you would normally run when
developing and testing the application. Docker Compose uses a yml file to
specify everything required to build and run the application and any other
support application (databases, volume containers, etc.) it requires. There are
multiple docker-compose yml files in the Application Root, explained below.

docker-compose.yml
---
This file is primarily intended for frontend developers, REST client
developers, and user analysts.

By default, docker-compose looks for a file called 'docker-compose.yml' in the
working directory where it is run. The docker-compose.yml for this application file
extends dc-base.yml (see below). It specifies the basic set of docker-compose
services required to get the DDS service running with its support services on
your machine.

Anyone with docker, docker-machine, and docker-compose can run the
following command from within the Application Root (where this file you are
reading resides), to build the server image and any other ancillary support
images that it needs (You must be connected to the internet so that docker can
pull down any base docker images, or package/gem installs, for this to work).
***This WILL take 20 minutes or more if you have never built the images***
```
docker-compose build
```
Once you have built the images, you can launch containers of all services
required by the app (docker calls a running instance of a docker image a docker
container):
```
docker-compose up -d server
```

**Note** there is a preferred method to [launch the application](#launching-the-application).

The docker-compose definition for this application service mounts the Application
Root as /var/www/app in the server docker container.  Since the Dockerfile specifies
/var/www/app as its default WORKDIR, this allows you to make changes to the files
on your machine and see them reflected live in the running server (although see
[below](#dockerfile) for **important information about modifying the Gemfile**).

The Dockerfile hosts the application to port 3000 inside the container,
and the docker-compose service definition attaches this to port 3001 on the docker-machine,
and serves the appliction using SSL by default on the VM host (this will fail if
you have another service of any kind attached to port 3001).
To connect to this host, you should use the following docker-machine command to find
the ip of the docker-machine:
```
docker-machine ip default
```
Then you can use curl, or your browser to connect to
https://$(docker-machine ip default):3001/api/v1/app/status to check the status of
the application. All other parts of the application are served at this ip.

To stop all running docker containers (you must stop a container before you can
remove it or its image):
```
docker-compose stop
```

When a docker container stops for any reason, docker keeps it around in its
system.  There are ways you can start and attach to a stopped container, but
in many cases this is not useful. You should remove containers on a regular basis.
**Note**, because we do not persist the data in our postgres databases, or swift services,
to the host file system, all of your databases and swift objects are removed when
you remove their stopped containers. When you start up the machines from scratch,
you will need to run rake db:migrate, etc. to get the database ready. You can
list all running containers using the following command:
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
using docker-compose (see Docker [commandline documentation](https://docs.docker.com/engine/reference/commandline)
for other things you can find out about a running container using the docker command):
```
docker stop UUID
docker rm -v UUID
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

Similarly, to remove all stopped containers (this will skip running containers, but
print a warning for each):
```
docker rm -v $(docker ps -aq)
```
(It is useful to alias this particular command in your bash_profile). We
recommend running this command frequently to clean up containers that build up
over time. If there are no stopped containers, docker will print a warning that
it requires 1 or more arguments, but this is ok.

dc-base.yml
---
This docker-compose YAML file defines the services that are shared by most other
docker-compose files in the directory. You should only edit it if you need to
permenently change the service definition for the webapp, db, swiftvol and swift
services.

dc-dev.utils.yml
---
This is the **recommended** docker compose file for developers.
This file extends dc-base.yml the same way the default docker-compose.yml file does,
and adds service definitions to make it possible to easily run things like bundle,
rspec, rails, rake, etc (see below for more).

You can use this file in one of two ways.
* add the -f dc-dev.utils.yml flag to all of your docker-compose commands, e.g.
```
docker-compose -f dc-dev.utils.yml up -d server
docker-compose -f dc-dev.utils.yml run rails c
```

An easier way to do this is to set the following shell environment variable:
```
export COMPOSE_FILE=dc-dev.utils.yml
```
(it may be useful to do this in your bash_profile)

In either case, you should always specify the exact service (e.g. top level key
in the dc-dev.utils.yml file) when running docker-compose commands. Otherwise,
docker-compose will try to run all services in the background which will cause
things to run that do not need to run (such as bundle).

Here is a list of docker-compose commands available using our dc-dev.utils.yml
(assume the COMPOSE_FILE environment as been set):

Launch the server and postgresdb to interact with the application:
```
docker-compose up -d server
```
Docker-compose is smart enough to realize all of the linked services required,
and spin them up in order.

Run the rspec
```
docker-compose run rspec
docker-compose run rspec spec/requests
docker-compose run rspec spec/models/user_spec.rb
```

Run bundle (see
[below](#dockerfile) for **important information about modifying the Gemfile**)):
```
docker-compose run bundle
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

Create an AuthenticationService object that links to the
[Duke Authentication Service](https://github.com/Duke-Translational-Bioinformatics/duke-authentication-service) container that is run from its Application Root using docker-compose
([see below](#connecting-a-duke-authentication-service-microservice)) **Note this must be run against
an existing, migrated database**:
```
docker-compose run authservice
```

Remove the authservice
```
docker-compose run authservice authservice:destroy
```

Create a StorageProvider linked to a swift service (defined in [swift.env](#running-a-local-swift-service-using-docker)]) **Note this must be run against
an existing, migrated database**:
```
docker-compose run storageprovider
```

Start a locally running swift storage service ([see below](#running-a-local-swift-service-using-docker)):
```
docker-compose up -d swift
```

Create an api test user ([see below](#creating-an-api_test_user-and-token)) **Note this must be run against an existing, migrated database**
```
docker-compose run rake api_test_user:create
```

Destroy the api_test_user (and all objects created by the user):
```
docker-compose run rake api_test_user:destroy
```

Clean up any objects created by the api_test_user, such as by [running the workflow](#running-the-workflow):
```
docker-compose run rake api_test_user:clean
```

Run the [dredd](#run-dredd) API specification tests (see below for how to
run this).

docker-compose.circle.yml
---
This docker-compose yml file is specifically configured for CircleCI. It
does not extend dc-base.yml. This is to ensure that it works with the version
of docker-compose that is made available on the CircleCI host machine.
**Developers should not use this file unless they are troubleshooting a
failed CircleCI build on the CircleCI machine**

Creating an API_TEST_USER and token
===
A rake task, api_test_user:create, has been written to create a
test user account to use in any test applications.  This creates
a single specific User (if it does not already exist). Each time it is run,
it will print a new api_token to STDOUT (even if the User already exists).
This api_token has an expiry of 5 years from the time the rake task is run.
Here is how you can create one and capture the token into a bash variable:
```
api_token=`docker-compose -f dc-dev.utils run rake api-test_user:create`
```
You can use this in any code that needs to access the API (see the [workflow](#running-the-workflow)
for an example).
If you want to use this in the swagger apiexplorer, launch the /apiexplorer,
open the javascript console, type
```
window.localStorage.api_token='yourtoken'
```
and reload the page.

Connecting to an Openstack Swift Object Store
===
Currently, DDS is designed to support a single Openstack Swift object storage,
using [version 1](http://developer.openstack.org/api-ref-objectstorage-v1.html) of the Swift API.
A StorageProvider object must be created for the target Swift service.

Configuration
---
The following Environment Variables must be set on the host server to configure
a StorageProvider object with information about the live Swift storage provider
for the DDS service:

* SWIFT_URL_ROOT: The base URL to the swift service.
The full URL for the swift account used by the DDS
is `${SWIFT_URL_ROOT}/${SWIFT_AUTH_URI}/${SWIFT_ACCT}`
* SWIFT_VERSION:  this must be the version of the swift API that the DDS uses,
which is specified in the SWIFT_AUTH_URI.
* SWIFT_AUTH_URI: This is part of the url used to access containers and objects in the
swift service. It is typically of the form /auth/vN
where N is the version of the swift API that the DDS uses.
The full URL for the swift account used by the DDS
is `${SWIFT_URL_ROOT}/${SWIFT_AUTH_URI}/${SWIFT_ACCT}`
* SWIFT_ACCT: The name of the swift service account, which is part of the
url used to access containers and objects in the swift service.
The full URL for the swift account used by the DDS
is `${SWIFT_URL_ROOT}/${SWIFT_AUTH_URI}/${SWIFT_ACCT}`
* SWIFT_DESCRIPTION: Used in the StorageProvider definition for the DDS service
* SWIFT_DISPLAY_NAME: Used in the StorageProvider definition for the DDS service
* SWIFT_USER: The user used with the SWIFT_PASS to authenticate the DDS
client to the swift service. These must be set up by
the swift service system administrator.
* SWIFT_PASS: The password for the SWIFT_USER used to authenticate the
DDS client to the swift service.  These must be set up by
the swift service system administrator.
* SWIFT_PRIMARY_KEY: A long random string which can be generated using
```
docker-compose run rake secret
```
This and the SWIFT_SECONDARY_KEY are registered with
the account used by the DDS service, and used to sign
the temporary_urls that are generated by the DDS to
allow clients to upload chunks and download files.
* SWIFT_SECONDARY_KEY: A different long random string, but generated and used
in the same way as the SWIFT_PRIMARY_KEY.

A rake task, storage_provider:create, has been created to facilitate the
creation of a StorageProvider. It uses these Environment variables.
You can destroy the storage_provider with the rake task storage_provider:destroy.

This repo includes an empty_swift.env file which is symlinked to swift.env,
and a swift.local.env which specifies these environment variables for the
[local swift service](#running-a-local-swift-service-using-docker).

**Note** The launch_application.sh script, and the storage_provider:create
rake task will do extra things when these Environment variables are set, such
as by copying or symlinking swift.local.env to swift.env. When the swift.env file
is not empty, launch_application.sh launches the local dockerized swift services,
attached to a volume container for the files.
(**NOTE** When you remove the stopped swift-vol container, all files stored to this
swift service are deleted). When the above SWIFT_ACCT environment variable is not
empty, storage_provider:create will attempt to register the SWIFT_PRIMARY_KEY and
SWIFT_SECONDARY_KEY with the specified swift service using its API.

Running a local swift service using Docker
===
All of the docker-compose yml files specify service definitions to
build a locally running swift service, configured to allows very small
static_large_object 'chunks' (see docker/builds/swift for the Docker build context).
To use this, change the swift.env to point to swift.local.env, and then launch
the application:
```
rm swift.env
ln -s swift.local.env swift.env
./launch_application.sh
```

Running the Workflow
===
A bash script, workflow.sh, has been created to test the locally running API using a set of
files. To run this:

- make sure you set the swift.env to point to the local_swift.env file
- create a freshly launched application (e.g. the postgres database and swift service
are completely clean). You can run the following to ensure this:
```
docker-compose stop
docker rm $(docker ps -aq)
```
- create an api_test_user
```
api_token=`rake api_test_user:create`
```
- run the workflow with the api_token
```
./workflow.sh ${api_token}
```

You will need to clean up after each run to get rid of all of the DDS objects, and Swift
containers/objects that are created, or the workflow will fail when it tries to create the
project with an existing name.
```
docker-compose stop
docker rm $(docker ps -aq)
```

Run Dredd
===
Dredd is a node application that runs against the official [Duke Data Services Apiary Documentation](http://docs.dukedataservices.apiary.io/) using the apiary.apib file
that is located in the Application Root, which should be up to date (if not, it should
be updated and committed to the master branch of the repo, and merged into all other
branches where dredd should run).

The dredd application has been wrapped into its own docker image, which can be built
and run using the dc-dev.utils.yml docker-compose file. Dredd must be run
against a running DDS service, which is configured to work with a running swift
storage service. It does not need a running Authentication Service to work, but
it does need the [Api Test User Token](#creating-an-api_test_user-and-token).

The dredd service in dc-dev.utils.yml uses an environment file in the Application Root,
dredd.env.  It must specify the host to which dredd will connect to test assigned
to HOST_NAME, and it must contain an api_token assigned to MY_GENERATED_JWT.
**NOTE** the default dredd.env file in the repository only contains the HOST_NAME.
It does not contain a MY_GENERATED_JWT. This should be generated and appended to
the dredd.env file before running the application, and any changes to dredd.env
should be discarded, and never committed to git.

The default dredd.env file is configured with a HOST_NAME to work with a locally
running dds server docker container linked to the dredd container using the
dredd.host hostname, running **without SSL**. This can be modified by
changing the dredd.env file to use a different HOST_NAME. The URL set for this
variable must be valid, such that accessing ${URL}/api/v1/app/status, such as in
a browser, or using curl, would return {'status': 'ok'}. In addition, the
DDS service must be configured to work with a running swift service. The default,
locally running dds server service should be run with a valid swift.env file
specifying a live swift service.

To run dredd against the default, locally running DDS server service, do the following:
```
rm swift.env
ln -s swift.local.env swift.env
rm webapp.env
ln -s circle/webapp.circle.env webapp.env
rm dredd.env
ln -s dredd.local.env dredd.env
export COMPOSE_FILE=docker-compose.circle.yml
./launch_application.sh
echo "MY_GENERATED_JWT="$(docker-compose run rake api_test_user:create | tail -1) >> dredd.env
docker-compose run dredd
```

To clean up after a dredd run (you should do this between runs, and also before committing
any code changes to git):
```
docker-compose stop
docker rm $(docker ps -aq)
git checkout -- dredd.env swift.env webapp.env
```

The API Explorer
===

The DDS service provides a [swagger](http://swagger.io/) client to users, which
provides documentation of the REST services, and allows users to interact with the
API. This service is hosted at /apiexplorer on the application. It requires that
the server be configured to work with a live Duke Authentication Service microservice.
See [Connecting a Duke Authentication Service microservice](#connecting-a-duke-authentication-service-microservice)
for details on how to work with this client on the locally running server instance.

In production, the API Explorer uses the APIEXPLORER_ID environment variable to
store the UUID used to identify the client to the Duke Authentication Service
microservice configured for the DDS server. This must be set on the host server
for the applicaton. It must also be registered along with the apiexplorer URL, and
DDS SECRET_KEY_BASE as a Consumer in the Duke Authentication Service server.

* See the configuration section of [Connecting a Duke Authentication Service microservice](#connecting-a-duke-authentication-service-microservice)
for information about registering Consumers with a Duke Authentication Service.
* See [Deploying Secrets](#deploying-secrets) for information on how to deploy
secrets to the host system.

The Portal
===

The DDS service provides a compiled distribution of the [Duke Data Service Portal](https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal).
This is a sinatra application configured into the Rack service at the /portal endpoint.

Configuration
---
In production, the portal requires the following Environment variables:
* SERVICE_ID: see [Production Configuration](#connecting-a-duke-authentication-service-microservice)
* AUTH_SERVICE_BASE_URI: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* AUTH_SERVICE_NAME: see [Configuration](#connecting-a-duke-authentication-service-microservice)

Note, these are designed to be kept in sync with the same environment variables
used in the DDS and /apiexplorer regarding communication with the Duke
Authentication Service.

Local Portal
---
To run locally, you must link the portal to a live [Duke Authentication Service microservice](#connecting-a-duke-authentication-service-microservice).

Generating the Compiled distribution
---
The dc-dev.utils.yml docker-compose file specifies the genportal service, which
builds and runs a docker image designed to do the following:
* git clone the latest Duke Data Service Portal repository
* install node and npm requirements to build the portal distribution
* build the distribution
* remove all files in the 'portal' directory in the DDS Application Root on your host machine
* copy the distribution files into the portal directory

To generate and publish a new version of the Portal into the DDS:
```
docker-compose -f dc-dev.utils.yml run genportal
```

If your duke-data-service-portal repository is cloned into the same directory
as this repository, e.g. ls ../duke-data-service-portal will print the contents
of that repo, you can run the genlocalportal service to generate the compiled portal
binaries from your local repo.
```
docker-compose -f dc-dev.utils.yml run genlocalportal
```

You should then add/rm, commit, and push all the newly generated files in the
portal directory.

Connecting a Duke Authentication Service microservice
===

Configuration
---
In production, the DDS server must be configured with the information for a live
Duke Authentication Service microservice. This requires three Environment variables:
* AUTH_SERVICE_ID: The SERVICE_ID configured in the live Duke Authentication Service
* AUTH_SERVICE_BASE_URI: The Base URI to the live Duke Authentication Service, e.g. URI/api/v1/app/status should return {'status': 'ok'}
* AUTH_SERVICE_NAME: A Description of the Service used in the apiexplorer and portal frontends

A rake task has been setup to create the AuthenticationService model object in the
server using these environment variables.
```
docker-compose -f dc-dev.utils.yml run rake authservice:create
```

You can also destroy the currently configured AuthenticationService definition:
```
docker-compose -f dc-dev.utils.yml run rake authservice:destroy
```

Production Configuration
---
For this rake task to work, the following environment variables must also be set on servers that
are not run in the development or test RAILS_ENV:
* SECRET_KEY_BASE: This is the standard secret_key_base set in all rails applications.
It can be generated by running ```docker-compose -f dc-dev.utils.yml rake secret```
* SERVICE_ID: a UUID, such as using the ruby SecureRandom.uuid function
* APIEXPLORER_ID: a UUID that is different from the SERVICE_ID.

Registering Consumers
---
Consumers must be registered with the live Duke Authentication Service (See
Documentation in the [Duke Authentication Service](https://github.com/Duke-Translational-Bioinformatics/duke-authentication-service)
for more information about registering consumers). The docker-compose files and
launch_application.sh scripts for the Authentication is configured to register
these correctly for the development environment. For other servers, you must
register the following Consumers using the Duke Authentication Service rake
consumer task + the following environment variables and values:
* API Explorer Consumer:
  * UUID: DDS APIEXPLORER_ID
  * REDIRECT_URI: URL to /apiexplorer on the DDS server
  * SECRET: DDS SECRET_KEY_BASE
* DDS Portal Consumer:
  * UUID: DDS SERVICE_ID
  * REDIRECT_URI: URL to /portal
  * SECRET: DDS SECRET_KEY_BASE

**NOTE** both use the same DDS SECRET_KEY_BASE, which allows the Authentication Service
to encode a JWT with this secret, which, for both clients, is eventually processed
by the DDS /user/api_token endpoint.

* See [Deploying Secrets](#deploying-secrets) for further information about deploying
secrets to the DDS host server.

Running locally
---
**Important** Only Duke Employees can build the Duke Authentication Service image.
It is possible to have a Duke Employee involved in the project provide access to
a Duke Authentication Service image for use by outside developers.

Duke Data Service frontend applications, such as the portal, or apiexplorer, require
a Duke Authentication Service microservice to provide authentication. Duke employees
can register their local machines to host shibboleth protected web applications,
and then clone, build and run a local [Duke Authentication Service](https://github.com/Duke-Translational-Bioinformatics/duke-authentication-service)
docker service. The Docker.README.md file in this project details how to configure,
your service with the official Duke Shibboleth registration system. You can
run the Duke Authentication Service docker image without being connected to the
Duke Medical Center VPN, but you must be connected to build the Duke Authentication
Service image (see the Docker.README.md file for the Duke Authentication service
for more details).

When you git clone the Duke Authentication Service repo, it comes with its own
docker-compose.yml and dc-dev.utils.yml specifying standard ports to use to
connect to it on the docker-machine. An AuthenticationService object must be
created in the Duke Data Service container to register a Duke Authentication Service,
and a Consumer object must be created in the Duke Authentication Service container
to register the Duke Data Service.
Both this repo and the Duke Authentication Service repo come with rake tasks
to create these objects once their respective db services have been started.

Assuming you are starting from scratch (e.g. you do not have any db containers
running or stopped for this or the Authentication Service), you can get both
up and running and wired together with the following set of commands (note PATHTO
should be the full path to the directory on your machine):

```
cd PATHTO/duke-authentication-service
./launch_application.sh
cd PATHTO/duke-data-service
./launch_application.sh
```

You should also stop and clean these containers when you are finished with them:
```
cd PATHTO/duke-authentication-service
docker-compose stop
cd PATHTO/duke-data-service
docker-compose stop
docker rm $(docker ps -aq)
```

Dockerfile
===
Docker uses a [Dockerfile](https://docs.docker.com/reference/builder/) to
specify how to build an image to host an application. We have created a
Dockerfile in the Application Root. This Dockerfile:
* installs required libraries for ruby, rails, node, etc.
* installs specific versions of ruby and node
* creates SSL certs
* installs the postgres client libraries
* creates /var/www/app and sets this to the default working directory
* checks out the latest version of the branch of the code from github into /var/www/app
* adds Gemfile and Gemfile.lock (see below)
* bundles to install required gems into the image
* exposes 3000
* sets up to run the puma server to host the service by default

**Important information about modifying the Gemfile**
When you need to add a gem to your Gemfile, you will also need to rebuild
the server. This will permenently install the new gem into the server image.

```
docker-compose build server
```
You then need to run bundle, which will update Gemfile.lock in the Application
Root
```
docker-compose run bundle
```
You should then commit and push the new Gemfile and Gemfile.lock to the repository.

Deploying Secrets
===
There are a variety of secrets that the DDS service needs to run, especially when
running in anything but the development environment. This is because the server
is configured to use ENVIRONMENT variables for these secrets:

* APIEXPLORER_ID: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* AUTH_SERVICE_ID: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* AUTH_SERVICE_BASE_URI: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* AUTH_SERVICE_NAME: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* SECRET_KEY_BASE: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* SERVICE_ID: see [Configuration](#connecting-a-duke-authentication-service-microservice)
* SWIFT_URL_ROOT: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_VERSION: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_AUTH_URI: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_ACCT: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_DESCRIPTION: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_DISPLAY_NAME: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_USER: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_PASS: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_PRIMARY_KEY: see [Configuration](#connecting-to-an-openstack-swift-object-store)
* SWIFT_SECONDARY_KEY: see [Configuration](#connecting-to-an-openstack-swift-object-store)

Rake Heroku Secret Deployment
---
Duke School of Medicine Employees connected to the Duke School of Medicine VPN
can use a rake task to deploy their secrets, using our internal [vault](https://vaultproject.io/)
service. The employee must also install, authenticate, and be authorized to use the
[heroku commandline tool](https://devcenter.heroku.com/articles/heroku-command) to deploy configuration to the duke data service heroku
applications. Users must also set the RAILS_ENV environment variable on their host
machine before running the rake task.

To deploy secrets to heroku:
```
export RAILS_ENV=development
docker-compose -f dc-dev.utils.yml run deploysecrets
```

Troubleshooting Docker
===
If your docker command is not wired to communicate with your docker machine, or
your docker-machine is not running, docker-compose will return the following
response:
Couldn't connect to Docker daemon - you might need to run `boot2docker up`.

To fix this, Do NOT run boot2docker up!  Docker machine takes care of this for you. Instead,
check the following:
1. Is your docker-machine running:
```
docker-machine ls
```

2. Is your docker ENVIRONMENT setup properly
```
eval $(docker-machine env default)
```

In some cases, the docker-machine VM gets shut down with an invalid state,
which causes it to fail to restart when you run docker-machine start default.
In this case, you should use the Virtualbox Application Interface to discard the
saved state of the machine (it is named 'default' if you crated the docker-machine
with 'default'). Right click on the machine in the left panel, and stop it if it is
not already stopped, then 'discard saved state'.

Bash Profile
===
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
===

The Cisco Anyconnect VPN client can be configured by the VPN systems
administrators to reconfigure your host network
in ways that prevent your docker binary from communicating with the docker machine
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
fix_anyconnect.sh default
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

**A further complication was introduced by the upgrade of Yosemite**.
In the Yosemite realease, the /sbin/ipfw command was removed! Yet, Cisco VPN can
still set up 'deny any from any' firewall rules. We have had success copying
/sbin/ipfw from a Mavericks mac to our Yosemite machine to restore the ability
of fix_anyconnect.sh to work.

It may also be possible to use the recommended apple firewall system to fix the
network.
