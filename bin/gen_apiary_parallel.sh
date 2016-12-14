#!/bin/bash

for apifile in *apib
do
  if [ ${apifile} == 'apiary.apib' ]
  then
    target='index.html'
  else
    target=`echo ${apifile} | sed 's/apib/html/'`
  fi
  echo "generating app/views/apidocs/${target}"
  docker-compose run genapiary -i ${apifile} -o app/views/apidocs/${target}
done
docker-compose down
echo "FIN"
