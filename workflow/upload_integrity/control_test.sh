#!/bin/bash

source includes/curl_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

source includes/run_upload_workflow.sh

offset=0
for i in $(echo "${upload_get_resp}" | jq -r '.chunks | sort_by(.number)[] | [(.number | tostring), (.size | tostring), .hash.value] | join(",")'); do
  chunk_number=$(echo $i | cut -d, -f1)
  chunk_size=$(echo $i | cut -d, -f2)
  expected_md5=$(echo $i | cut -d, -f3)
  download_md5=`dd skip=${offset} count=${chunk_size} if=${download_location} of=/dev/stdout bs=1 status=none | md5sum | cut -f1 -d' '`
  echo Testing md5 for chunk number ${chunk_number} of size ${chunk_size}
  echo Expected: ${expected_md5}
  echo Actual: ${expected_md5}
  offset=$((offset + chunk_size))
done

downloaded_file_size=`wc -c ${upload_location} | cut -f1 -d' '`
downloaded_file_md5=`md5sum ${upload_location} | cut -f1 -d' '`

echo Test total file size
echo Download: ${downloaded_file_size}
echo Original: ${upload_size}

echo Test file MD5
echo Download: ${downloaded_file_md5}
echo Original: ${upload_md5}
