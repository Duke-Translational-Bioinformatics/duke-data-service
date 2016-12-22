#!/bin/bash

for apifile in `ls -1 api_docs`
do
  if [ ${apifile} == 'apiary.apib' ]
  then
    target='index.html'
  else
    target=`echo ${apifile} | sed 's/apib/html/'`
  fi
  echo "generating ${target}"
  aglio -i api_docs/${apifile} -o public/apidocs/${target}
done
echo "FIN"
