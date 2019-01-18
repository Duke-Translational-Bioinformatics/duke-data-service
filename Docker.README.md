Development with Docker
===
We use [Docker](https://www.docker.com/) to run, test, and debug our application.
The following documents how to install and use Docker on a Mac. There are
[instructions](https://docs.docker.com/installation) for installing and using
docker on other operating systems.

On the mac, we use [docker for mac](https://docs.docker.com/engine/installation/mac/#/docker-for-mac).

We use [docker-compose](https://docs.docker.com/compose/) to automate most of
our interactions with the application.

Table of Contents
===
* [Installation and Upgrade](#installation-and-upgrade)
* [Launching the Application](#launching-the-application)
* [Docker Compose](#docker-compose)
* [Creating an API_TEST_USER and token](#creating-an-api_test_user-and-token)
* [Connecting to an Openstack Swift Object Store](#connecting-to-an-openstack-swift-object-store)
* [Running a local swift service using Docker](#running-a-local-swift-service-using-docker)
* [Running the Workflow](#running-the-workflow)
* [Run Dredd](#run-dredd)
* [The Api Explorer](#the-api-explorer)
* [Connecting a Duke Authentication Service microservice](#connecting-a-duke-authentication-service-microservice)
* [Dockerfile](#dockerfile)
* [Deploying Secrets](#deploying-secrets)
* [Useful Docker Commands](#useful-docker-commands)
* [Bash Profile](#bash-profile)

Installation and Upgrade
===
Docker makes it easy to install docker for mac, which includes docker, and docker-compose
on your mac, and keep them upgraded in sync.  Follow the instructions
to install [Docker 4 Mac]((https://docs.docker.com/engine/installation/mac/#/docker-for-mac).

Once you have docker running, you can run any of the following commands to test
that docker is working:
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
* use rake to:
  * migrate and seed the database
  * create an AuthService using auth_service.env
  * create a StorageProvider using swift.env (this may not do anything if swift.env
    is empty).

**Use this script to launch the application**, and read on for how this
script works, and how you can utilize docker and docker-compose to develop and
test the system.

Docker Compose
===

Once you have docker installed, you can use docker-compose to run all of the
commands that you would normally run when developing and testing the application.
Docker Compose uses one or more yml files to specify everything required to build
and run the application and any other support application (databases, volume
containers, etc.) it requires. There are multiple docker-compose yml files in
the Application Root, explained below.

docker-compose.yml
---
This is the base docker-compose file used to manage the server, postgres db, and
neo4j db required to test and run the service.

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
docker-compose up -d
```

**Note** there is a more preferred method to [launch the application](#launching-the-application).

The docker-compose definition for the 'server' service mounts the Application
Root as /var/www/app in the server docker container.  Since the Dockerfile specifies
/var/www/app as its default WORKDIR, this allows you to make changes to the files
on your machine and see them reflected live in the running server (although see
[below](#dockerfile) for **important information about modifying the Gemfile**).

The Dockerfile hosts the application on port 3000 inside the container,
and the docker-compose service definition attaches this to port 3001 on the
host machine (this will fail if you have another service of any kind attached to
port 3001 on the same host).
To connect to this host you can use curl, or your browser to connect to
http://localhost:3001/api/v1/app/status to check the status of
the application. All other parts of the application are served at
http://localhost:3001.

docker-compose.dev.yml
---
This file extends docker-compose.yml to add service definitions to make it possible
to easily run things like bundle, rspec, rails, rake, etc (see below for more).

You can use this by adding the -f docker-compose.yml -f docker-compose.dev.yml flag
to all of your docker-compose commands, e.g.
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rails c
```

Alternatively, you can use the fact that docker-compose looks for both docker-compose.yml
and docker-compose.override.yml by default, and create a symlink from docker-compose.dev.yml
to docker-compose.override.yml that will make docker-compose use both by default, without
any of the extra -f flags.
```
ln -s docker-compose.dev.yml docker-compose.override.yml
```
Note, docker-compose.override.yml is in the .gitignore, so it will never be committed
to the repo. This ensures that the default behavior for those not wishing to use the
extra functionality in docker-compose.dev.yml is preserved.

You should always specify the exact service (e.g. top level key
in the docker-compose.dev.yml file) when running docker-compose commands using this
docker-compose.dev.yml file. Otherwise, docker-compose will try to run all services,
which will cause things to run that do not need to run (such as bundle).

docker-compose.swift.yml
---

This file extends docker-compose.yml and docker-compose.dev.yml (it should be
used with both) to launch and link the server and developer utils (rspec, rake,
rails, etc.) with a running swift instance container. **Note** The system is not
set up by default to run the swift service. We use the vcr gem to record calls to
swift for future tests to use, which makes it possible for most of our development
work to be done without a running swift instance.

If you wish to make running the swift services part of the default behavior of docker-compose,
without needing the -f flags, set your COMPOSE_FILE environment variable to a colon
separated list of these three files:
```
export COMPOSE_FILE='docker-compose.yml:docker-compose.dev.yml:docker-compose.swift.yml'
```
Again, if you do this, be sure never to run docker-compose up -d without specifying individual
services, or unexpected services will be run and errors will result.

default docker-compose commands
---
Using just the docker-compose.yml, e.g. no COMPOSE_FILE environment variable, and
docker-compose.override.yml file/symlink is not present:

Launch the server, postgresdb, and neo4j to interact with the application:
```
docker-compose up -d server
```
Docker-compose is smart enough to realize all of the linked services required,
and spin them up in order. This will not launch a swift service.

Bring down and delete running containers:
```
docker-compose down
```

docker-compose.dev.yml docker-compose commands
---
Either use -f docker-compose.yml -f docker-compose.dev.yml, like so:
Run rspec
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rspec
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rspec spec/requests
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rspec spec/models/user_spec.rb
```

Or create a symlink from docker-compose.dev.yml to docker-compose.override.yml.
This is the recommended way to use docker-compose.dev.yml, as it will be more
permenant between invocations of the shell terminal, unless you add the COMPOSE_FILE
environment setting to your ~/.bash_profile.
```
ln -s docker-compose.dev.yml docker-compose.override.yml
```

Then you can run services like rspec without the extra -f flags:
```
docker-compose run rspec
docker-compose run rspec spec/requests
```

Alternatively, you can create a COMPOSE_FILE environment variable and get the same
default behavior.
```
export COMPOSE_FILE='docker-compose.yml:docker-compose.dev.yml'
```
This will last only as long as your current shell terminal session, unless you add
the above command to your ~/.bash_profile.

The following commands assume the symlink, or COMPOSE_FILE environment variable exists.
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

Run rails commands (default RAILS_ENV=docker):
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
docker-compose run rake authservice:destroy
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

docker-compose.swift.yml docker-compose commands
---
Either use -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml, like so:
Run rspec
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.env run swift
```

Or create the COMPOSE_FILE environment variable.
```
export COMPOSE_FILE='docker-compose.yml:docker-compose.dev.yml:docker-compose.swift.yml'
```

Again, if you want this to last between shell terminal sessions, add the above to
your ~/.bash_profile.

This repo does not provide a yml file that combines the services in docker-compose.dev.yml
and docker-compose.swift.yml together into a single file that could be used as a
docker-compose.override.yml, but this is certainly possible.

The following assume the COMPOSE_FILE environment is set.

Start a locally running swift storage service ([see below](#running-a-local-swift-service-using-docker)):
```
docker-compose up -d swift
```

Create a StorageProvider linked to a swift service (defined in [swift.env](#running-a-local-swift-service-using-docker)]) **Note this must be run against an existing, migrated database, and the swift service should be running**:
```
docker-compose run rake storageprovider:create
```

Run the [dredd](#run-dredd) API specification tests (see below for how to
run this). **Note** the dredd service is actually defined in docker-compose.dev.yml,
but it should be run with the docker-compose.swift.yml against a running swift.

**Note about docker-compose down**
You should run docker-compose down using the same docker-compose yml file context,
e.g. with COMPOSE_FILE set, or the docker-compose.override.yml file in existence,
or using the -f flags for all docker-compose yml files. Otherwise, services defined
in the missing docker-compose.yml file will not be shut down and removed, and a warning
may come up in your output that says containers were 'orphaned'.

docker-compose.circle.yml
---
This docker-compose yml file is specifically configured for CircleCI. This is to ensure that it works with the version
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
api_token=`docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rake api-test_user:create`
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
A SwiftStorageProvider object must be created for the target Swift service.

Configuration
---
The following Environment Variables must be set on the host server to configure
a SwiftStorageProvider object with information about the live Swift storage provider
for the DDS service:

* STORAGE_PROVIDER_TYPE: swift
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
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rake secret
```
This and the SWIFT_SECONDARY_KEY are registered with
the account used by the DDS service, and used to sign
the temporary_urls that are generated by the DDS to
allow clients to upload chunks and download files.
* SWIFT_SECONDARY_KEY: A different long random string, but generated and used
in the same way as the SWIFT_PRIMARY_KEY.

A rake task, storage_provider:create, has been created to facilitate the
creation of a StorageProvider. It uses these Environment variables.

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
The docker-compose.swift.yml file specifies the service definition to
build a locally running swift service, configured to allow very small
static_large_object 'chunks' (see docker/builds/swift for the Docker build context).
To use this, change the swift.env to point to swift.local.env, and then launch
the application:
```
rm swift.env
ln -s swift.local.env swift.env
./launch_application.sh
```

**Note** In order to run the server, or any rails, rake, rspec commands against
the running swift service, you must run these with the docker-compose.swift.yml
file included in the chain of docker-compose files, e.g with the -f flags,
the COMPOSE_FILE set, or a specially crafted docker-compose.override.yml.
Otherwise, the application containers are not linked to the swift service. This
will cause any attempts to communicate with the swift service, such as when starting
or completing an upload, to timeout. You will also need to use this chain to run
docker-compose down, docker-compose stop, etc:
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml stop swift
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml down
```

Running the Workflow
===
A bash script, workflow.sh, has been created to test the locally running API using a set of
files. To run this:

- make sure you set the swift.env to point to the swift.local.env file
- create a freshly launched application (e.g. the postgres database and swift service
are completely clean). You can run the following to ensure this:
```
rm swift.env
ln -s swift.local.env swift.env
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml down
./launch_application.sh
```
- create an api_test_user
```
api_token=`docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rake api_test_user:create`
```
- run the workflow with the api_token
```
˝./workflow/workflow.sh ${api_token}
```

You will need to clean up after each run to get rid of all of the DDS objects, and Swift
containers/objects that are created, or the workflow will fail when it tries to create the
project with an existing name.
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml down
```

Run Dredd
===
Dredd is a node application that runs against the official [Duke Data Services Apiary Documentation](http://docs.dukedataservices.apiary.io/) using the apiary.apib file
that is located in the Application Root, which should be up to date (if not, it should
be updated and committed to the master branch of the repo, and merged into all other
branches where dredd should run).

The dredd application has been wrapped into its own docker image, which can be built
and run using the docker-compose.dev.yml docker-compose file. Dredd must be run
against a running DDS service, and swift service, and the DDS service must be configured
to work with a running swift storage service. It does not need a running Authentication
Service to work, but it does need the [Api Test User Token](#creating-an-api_test_user-and-token).

To run dredd against the default, locally running DDS server service, do the following:
```
rm swift.env
ln -s swift.local.env swift.env
rm webapp.env
ln -s webapp.local.env webapp.env
./launch_application.sh
MY_GENERATED_JWT=$(docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rake api_test_user:create | tail -1)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml run -e "MY_GENERATED_JWT=${MY_GENERATED_JWT}" -e "HOST_NAME=http://dds.host:3000/api/v1" dredd
```

To clean up after a dredd run (you should do this between runs, and also before committing
any code changes to git):
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.swift.yml down
git checkout -- dredd*env swift*env webapp*env
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
for the application. It must also be registered along with the apiexplorer URL, and
DDS SECRET_KEY_BASE as a Consumer in the Duke Authentication Service server.

* See the configuration section of [Connecting a Duke Authentication Service microservice](#connecting-a-duke-authentication-service-microservice)
for information about registering Consumers with a Duke Authentication Service.
* See [Deploying Secrets](#deploying-secrets) for information on how to deploy
secrets to the host system.

Connecting a Duke Authentication Service microservice
===

Configuration
---
In production, the DDS server must be configured with the information for a live
Duke Authentication Service microservice. This requires three Environment variables:
* AUTH_SERVICE_SERVICE_ID: The SERVICE_ID configured in the live Duke Authentication Service
* AUTH_SERVICE_BASE_URI: The Base URI to the live Duke Authentication Service, e.g. URI/api/v1/app/status should return {'status': 'ok'}
* AUTH_SERVICE_NAME: A Description of the Service used in the apiexplorer and portal frontends

A rake task has been setup to create the AuthenticationService model object in the
server using these environment variables.
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rake authservice:create
```

You can also destroy the currently configured AuthenticationService definition:
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rake authservice:destroy
```

Production Configuration
---
For this rake task to work, the following environment variables must also be set on servers that
are not run in the development or test RAILS_ENV:
* SECRET_KEY_BASE: This is the standard secret_key_base set in all rails applications.
It can be generated by running ```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml rake secret
```
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
docker-compose.yml and docker-compose.dev.yml specifying standard ports to use to
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
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run bundle
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

Docker basics
===

To stop all running docker containers (you must stop a container before you can
remove it or its image):
```
docker-compose stop
```

To stop and/or remove all containers, use the following:
```
docker-compose down
```

When a docker container stops for any reason, docker keeps it around in its
system. There are ways you can start and attach to a stopped container, but
in many cases this is not useful. You should remove containers on a regular basis.
**Note**, because we do not persist the data in our postgres databases, or swift
services, to the host file system, all of your databases and swift objects are
removed when you remove their stopped containers. When you start up the machines
from scratch, you will need to run rake db:migrate, etc. to get the database ready.
This makes it easy to test the application against a clean slate system.
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

You may also need to check for volumes that have been left behind when containers
were removed without explicitly using docker rm -v, such as when docker-compose down
is run.  To list all volumes on the docker host:
```
docker volume ls
```

The output from this is very similar to all other docker outputs. Each volume is
assigned a UUID. You can remove a specific volume with:
```
docker volume rm UUID
```

You can remove all volumes using the -q pattern used in other docker commands
```
docker volume rm $(docker volume ls -q)
```

We recommend running some of these frequently to clean up containers and volumes that
build up over time. Sometimes, when running a combination docker rm $(docker ls -q)
pattern command when there is nothing to remove, docker will print a warning that
it requires 1 or more arguments, but this is ok. It can be useful to put some or
all of these in your Bash Profile.

Bash Profile
===
The following can be placed in the .bash_profile file located in your
HOME directory (e.g. ~/.bash_profile)

```bash_profile
# Docker configurations and helpers
alias docker_stop_all='docker stop $(docker ps -q)'
alias docker_cleanup='docker rm -v $(docker ps -aq)'
alias docker_images_cleanup='docker rmi $(docker images -f dangling=true -q)'
alias docker_volume_cleanup='docker volume rm $(docker volume ls -q)'

# fake rake/rails/rspec using docker under the hood
# this depends on either a docker-compose.override.yml, or COMPOSE_FILE
# environment variable
alias rails="docker-compose run rails"
alias rake="docker-compose run rake"
alias rspec="docker-compose run rspec"
alias bundle="docker-compose run bundle"
alias dcdown="docker-compose down"
```
