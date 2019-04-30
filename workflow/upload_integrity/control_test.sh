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
