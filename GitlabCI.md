Gitlab CI
---

The Duke Dataservice can make use of GitlabCI to augment the standard
build and deployment process currently provided by CircleCI. The
GitlabCI platform allows us to test different processes to monitor the
quality of our code, such as linting and code coverage, that do easily
not fit into the CircleCI structure.

#### Gitlab Github Mirroring
For this to work, a project must be created in a Gitlab host that
supports GitHub mirroring (this is an Enterprise feature). The project
must mirror the GitHub owner/repo to a gitlab owner/repo. **NOTE**
THE REPO NAME IN GITHUB MUST MATCH THE REPO NAME IN GITLAB.

#### Gitlab CI Pipeline Setup
Once the Gitlab Github Mirror project is setup, you should create the following variables in its Settings->CI/CI->Variables:

- APPLICATION_NAME: This should match the repo name, e.g. duke-data-service
- BUILDER_IMAGE_NAME: This parameter is passed to the build template
  to specify which builder image is used to build the application
- OPENSHIFT_PROJECT: The name of the Openshift project created to
  host the ci processes.
- BUILDER_IMAGE_NAMESPACE: Most likely this will equal   
  the value in OPENSHIFT_PROJECT.
- OPENSHIFT_API_TOKEN: This is the access token for the
gitlab-ci-runner service account. See [Service Accounts](https://docs.okd.io/latest/dev_guide/service_accounts.html#using-a-service-accounts-credentials-externally) for more information.
- OPENSHIFT_API_URL: the base url to the Openshift API.

#### Openshift
Openshift can host the processes run by GitlabCI. This requires
the following to be created in an Openshift cluster:
- new project: This should be done by hand, or by the Openshift Administrators.
- gitlab deployment ssh key secret annotated to be used on any build
  with source ssh://gitlab.oit.duke.edu/*
```bash
oc create secret generic gitlab-deploy-key \
   --from-file=ssh-privatekey=<FULL PATH TO SSH KEY> \
   --type=kubernetes.io/ssh-auth
oc annotate secret gitlab-deploy-key 'build.openshift.io/source-secret-match-uri-1=ssh://gitlab.oit.duke.edu/*'
```
- gitlab-ci-runner service account with the edit role on the project.
(see Prepare Gitlab Ci Runner Environment below)
- ori-rad-ruby ImageStream
(see Prepare Gitlab Ci Runner Environment below)
- dds-ruby ImageStream
(see Prepare Gitlab Ci Runner Environment below)
- duke-data-service ImageStream
(see Prepare Gitlab Ci Runner Environment below)
- ori-rad-ruby BuildConfig
(see Prepare Gitlab Ci Runner Environment below)
- dds-ruby BuildConfig
(see Prepare Gitlab Ci Runner Environment below)
- build-duke-data-service Openshift Template
(see Build Template below)

#### Prepare Gitlab CI Runner Environment
A single YAML file can be used with the oc command to
create most of the above requirements.
```bash
oc create -f openshift/prepare-gitlab-ci-runner-environment.yml
```

#### Build Template
The build process passes many of the Gitlab CI Variable as parameters
to an Openshift template called 'build-duke-data-service'. This makes
it easy to parameterize the build to any branch/tag on which the build
is being run to produce images in the duke-data-service ImageStream
tagged for the branch/tag (messaged to be Kubernetes compliant).
This template can be created with the following command:
```bash
oc create -f openshift/build-duke-data-service.template.yml
```
You can test the template by editing the openshift/build_params file
to have the correct values, and running
```bash
oc process build-duke-data-service --param-file=openshift/build_params | oc create -f -
```
