#!/bin/bash

source includes/curl_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo "${upload_create_payload}" | jq
echo Create upload with: ${upload_create_payload}
resp=$(dds_curl POST "/projects/${project_id}/uploads" ${upload_create_payload})
echo "${resp}" | jq

upload_id=`echo "${resp}" | jq -r '.id'`

echo Create chunk_1 with: ${chunk_1_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_1_payload})
echo "${resp}" | jq
upload_data ${chunk_1_location} ${resp}

echo Create chunk_2 with: ${chunk_2_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_2_payload})
echo "${resp}" | jq
upload_data ${chunk_2_location} ${resp}

echo Create chunk_3 with: ${chunk_3_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_3_payload})
echo "${resp}" | jq
upload_data ${chunk_3_location} ${resp}

echo Create chunk_4 with: ${chunk_4_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_4_payload})
echo "${resp}" | jq
upload_data ${chunk_4_location} ${resp}

echo Complete upload with: ${upload_complete_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/complete" ${upload_complete_payload})
echo "${resp}" | jq

file_create_payload='{"parent":{"kind":"dds-project","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}'
echo Complete upload with: ${file_create_payload}
resp=$(dds_curl POST "/files" ${file_create_payload})
echo "${resp}" | jq
file_id=`echo "${resp}" | jq -r '.id'`

echo Get download url for file id: ${file_id}
resp=$(dds_curl GET "/files/${file_id}/url")
echo "${resp}" | jq
download_data ${download_location} ${resp}

echo Get Upload info: ${upload_id}
resp=$(dds_curl GET "/uploads/${upload_id}")
echo "${resp}" | jq

offset=0
for i in $(echo "${resp}" | jq -r '.chunks | sort_by(.number)[] | [(.number | tostring), (.size | tostring), .hash.value] | join(",")'); do
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
