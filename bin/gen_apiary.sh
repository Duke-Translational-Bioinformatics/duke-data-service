#!/bin/bash

for apifile in `ls -1 api_docs`
do
  if [ ${apifile} == 'apiary.apib' ]
  then
    target='index.html.erb'
    echo "generating ${target}"
    aglio -i api_docs/${apifile} -o - | bin/parse_apiary.js > app/views/apidocs/${target}
  else
    target=`echo ${apifile} | sed 's/apib/html/'`
    echo "generating ${target}"
    aglio -i api_docs/${apifile} -o - | bin/apiary_section.js > app/views/apidocs/_${target}
  fi
done
echo "FIN"
