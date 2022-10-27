# duke-data-service

*** This Project is no longer being maintained ***

See the `develop` branch for active commits.

This is an open source project for building a "data service" for researchers that allows them to:

1. Have a unified interface for storing and managing research data across multiple internal (enterprise data stores) and external (cloud data stores)
2. Have persistent unique resource locators for their data
3. Have Project-level access control lists (ACLs) to manage collaborators' permissions
3. Generate Provenance according to the W3C specification either programmatically or via a graphical user interface
4. Provide a RESTful API for data storage and management
5. Integrate with containerization technology for managing research computing environments
6. Manage research data workflows

## sub-repositories
* https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal
* https://github.com/Duke-Translational-Bioinformatics/duke-authentication-service
* https://github.com/Duke-Translational-Bioinformatics/duke-storage-service
* https://github.com/Duke-Translational-Bioinformatics/repository-dashboard-shiny

## api blueprint
https://api.dataservice.duke.edu/apidocs

### circleci development
[![Circle CI](https://circleci.com/gh/Duke-Translational-Bioinformatics/duke-data-service/tree/develop.svg?style=svg)](https://circleci.com/gh/Duke-Translational-Bioinformatics/duke-data-service/tree/develop)

### circleci ua-test
[![Circle CI](https://circleci.com/gh/Duke-Translational-Bioinformatics/duke-data-service/tree/ua_test.svg?style=svg)](https://circleci.com/gh/Duke-Translational-Bioinformatics/duke-data-service/tree/ua_test)

### circleci production
[![Circle CI](https://circleci.com/gh/Duke-Translational-Bioinformatics/duke-data-service/tree/production.svg?style=svg)](https://circleci.com/gh/Duke-Translational-Bioinformatics/duke-data-service/tree/production)

### converse
[![Join the chat at https://gitter.im/Duke-Translational-Bioinformatics/duke-data-service](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Duke-Translational-Bioinformatics/duke-data-service?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


### contributing
The master branch of the project is considered the stable, production branch.
All commits should propogate from 'develop' to 'uatest', and then to master
only after UA Testing has approved changes to the code.

Contributing to the Project
###########################

The Duke-Data-Service project uses a fork and pull-request contribution model.  Developers
wishing to use github to contribute to the project should fork the
['official' repo](https://github.com/Duke-Translational-Bioinformatics/duke-data-service) into your
personal github account.  You should then set up a 'develop' branch, if it does
not already exist.  You **SHOULD** delete the 'master', 'production' and ua_test
branches if they exist, as we will never allow pull requests into these from
forked repos.
Also, you should set your default branch in your github repo to 'develop' if it
is set to 'master' or something else, and delete master if it exists (we will not
use master).

You should then clone your personal fork into your workstation, and use it
to develop changes. You can create as many branches in your local, or
forked repo, but these should never be pushed to official unless there is a
very good reason for doing so (such as a specific need to test a branch in circle-ci).

Once you are ready to submit your changes to the official repo, merge and push them
into your 'develop' branch, and then submit a pull request from your 'develop' to
the official 'developm' branch **MAKE SURE NOT TO CREATE A PR TO PRODUCTION**

Once you have cloned your fork into your working directory, it is useful to
perform the following commands, using the git commandline, to create a
**Fetch Only** official remote:
```
git remote add official git@github.com:Duke-Translational-Bioinformatics/duke-data-service.git
git remote set-url --push official donotpush
```

This allows you to fetch from official and merge those changes into your branches,
but does not allow you to accidentally push anything to official.

There are ways to configure gui clients this way too, but this is beyond the scope
of this document.

For developers that have been working directly off of the official repo,
and want to convert their existing clones to work this way, run the following:
```
git remote remove origin
git remote add origin ${PERSONAL_GIT_REPO_URL}
```
