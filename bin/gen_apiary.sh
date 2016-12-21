#!/bin/bash

for apifile in `ls -1 api_docs`
do
  if [ ${apifile} == 'apiary.apib' ]
  then
    target='index.html'
  else
    target=`echo ${apifile} | sed 's/apib/html/'`
  fi
  echo "generating app/views/apidocs/${target}"
  docker-compose run genapiary -i api_docs/${apifile} -o app/views/apidocs/${target}
done
docker-compose down
echo "FIN"
