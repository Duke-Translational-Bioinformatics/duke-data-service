#!/bin/bash

build_portal=${USE_LOCAL_PORTAL}
if [ ! ${USE_LOCAL_PORTAL}  ]
then
  echo "checking for new commits in github"
  last_commit=`awk '{print $1}' /var/www/app/portal.version`
  next_commit=`git ls-remote https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal.git refs/heads/develop | awk '{print $1}'`
  if [ ${last_commit} != ${next_commit} ]
  then
    build_portal=1
  fi
fi

if [ ${build_portal}  ]
then
  cd /var/www/app
  dds_branch=`git branch | grep '^*' | awk '{print $NF}'`
  cd /var/www
  if [ ${USE_LOCAL_PORTAL} ]
  then
    echo "building local repo"
    cd /var/www/duke-data-service-portal
  else
    echo "cloning from github"
    git clone https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal.git
    cd /var/www/duke-data-service-portal
    portal_branch=`git branch | grep '^*' | awk '{print $NF}'`
    if [ ${dds_branch} != ${portal_branch} ]
    then
      echo "checking out ${dds_branch}"
      git checkout ${dds_branch}
    fi
  fi
  npm install react-cookie
  npm install
  gulp build --type production
  rm -rf /var/www/app/portal/*
  cp dist/index.erb /var/www/app/portal/index.erb
  rsync -avz dist/ /var/www/app/portal/
  git ls-remote https://github.com/Duke-Translational-Bioinformatics/duke-data-service-portal.git "refs/heads/${dds_branch}" > /var/www/app/portal.version
  echo "Generated ${next_commit}"
else
  echo "nothing new"
fi
exit
