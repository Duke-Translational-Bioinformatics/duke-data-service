#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

source includes/run_upload_workflow.sh

echo Test chunks:
echo "Chunk #	| Size  | Expected MD5                     | Actual MD5"
echo "-------	| ----- | ------------                     | ----------"
offset=0
for chunk in $(echo "${upload_get_resp}" | jq --compact-output '.chunks | sort_by(.number)[]'); do
  chunk_number=$(echo "${chunk}" | jq -r '.number')
  chunk_size=$(echo "${chunk}" | jq -r '.size')
  expected_md5=$(echo "${chunk}" | jq -r '.hash.value')
  actual_md5=$(chunk_md5sum "${chunk}" ${download_location})
  echo "${chunk_number}	| ${chunk_size}	| ${expected_md5} | ${actual_md5}"
  offset=$((offset + chunk_size))
done

downloaded_file_size=`wc -c ${upload_location} | cut -f1 -d' '`
downloaded_file_md5=`md5sum ${upload_location} | cut -f1 -d' '`

echo Test total file:
echo "         | Size	| MD5"
echo "-------- | ----	| ---"
echo "Expected | ${upload_size}	| ${upload_md5}"
echo "Actual   | ${downloaded_file_size}	| ${downloaded_file_md5}"
