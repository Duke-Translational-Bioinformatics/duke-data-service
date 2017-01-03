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
  # add html hack to provide a quick link back to the API summary (index) page
  aglio -i api_docs/${apifile} -o - | \
  	sed 's/<section id="api-summary" class="resource-group"><h2 class="group-heading"><< API Summary <a href="#api-summary" class="permalink">&para;<\/a><\/h2><\/section>//' | \
  	sed 's/<div class="resource-group"><div class="heading"><div class="chevron"><i class="open fa fa-angle-down"><\/i><\/div><a href="#api-summary"><< API Summary<\/a><\/div><div class="collapse-content"><ul><\/ul><\/div><\/div>/<div><div class="heading"><div class="chevron"><i><\/i><\/div><b><a href="\/apidocs"><< API Summary<\/a><\/b><\/div><div><ul><\/ul><\/div><\/div>/' > \
  	public/apidocs/${target}
done
echo "FIN"
