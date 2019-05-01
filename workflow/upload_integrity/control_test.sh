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

echo Test Chunk 1 MD5
offset=0
downloaded_chunk_1_md5=`dd skip=${offset} count=${chunk_1_size} if=${download_location} of=/dev/stdout bs=1 status=none | md5sum | cut -f1 -d' '`
echo Download: ${downloaded_chunk_1_md5}
echo Original: ${chunk_1_md5}

echo Test Chunk 2 MD5
offset=$((offset + chunk_1_size))
downloaded_chunk_2_md5=`dd skip=${offset} count=${chunk_2_size} if=${download_location} of=/dev/stdout bs=1 status=none | md5sum | cut -f1 -d' '`
echo Download: ${downloaded_chunk_2_md5}
echo Original: ${chunk_2_md5}

echo Test Chunk 3 MD5
offset=$((offset + chunk_2_size))
downloaded_chunk_2_md5=`dd skip=${offset} count=${chunk_3_size} if=${download_location} of=/dev/stdout bs=1 status=none | md5sum | cut -f1 -d' '`
echo Download: ${downloaded_chunk_2_md5}
echo Original: ${chunk_3_md5}

echo Test Chunk 4 MD5
offset=$((offset + chunk_3_size))
downloaded_chunk_2_md5=`dd skip=${offset} count=${chunk_4_size} if=${download_location} of=/dev/stdout bs=1 status=none | md5sum | cut -f1 -d' '`
echo Download: ${downloaded_chunk_2_md5}
echo Original: ${chunk_4_md5}
