# This is runs a complete upload workflow using 4 chunks
# Default variables are set in includes/default_variables.sh

# Verbose output goes to file descriptor 7,
# which is directed to /dev/null by default
2>&- >&7 || exec 7>/dev/null

echo Create upload with: ${upload_create_payload} >&7
upload_create_resp=$(dds_curl POST "/projects/${project_id}/uploads" ${upload_create_payload})
echo "${upload_create_resp}" | jq '.' >&7

upload_id=`echo "${upload_create_resp}" | jq -r '.id'`

echo Create chunk_1 with: ${chunk_1_payload} >&7
chunk_1_create_resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_1_payload})
echo "${chunk_1_create_resp}" | jq '.' >&7
upload_data ${chunk_1_location} ${chunk_1_create_resp}

echo Create chunk_2 with: ${chunk_2_payload} >&7
chunk_2_create_resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_2_payload})
echo "${chunk_2_create_resp}" | jq '.' >&7
upload_data ${chunk_2_location} ${chunk_2_create_resp}

echo Create chunk_3 with: ${chunk_3_payload} >&7
chunk_3_create_resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_3_payload})
echo "${chunk_3_create_resp}" | jq '.' >&7
upload_data ${chunk_3_location} ${chunk_3_create_resp}

echo Create chunk_4 with: ${chunk_4_payload} >&7
chunk_4_create_resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_4_payload})
echo "${chunk_4_create_resp}" | jq '.' >&7
upload_data ${chunk_4_location} ${chunk_4_create_resp}

echo Complete upload with: ${upload_complete_payload} >&7
upload_complete_resp=$(dds_curl PUT "/uploads/${upload_id}/complete" ${upload_complete_payload})
echo "${upload_complete_resp}" | jq '.' >&7

file_create_payload='{"parent":{"kind":"dds-project","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}'
echo Complete upload with: ${file_create_payload} >&7
file_create_resp=$(dds_curl POST "/files" ${file_create_payload})
echo "${file_create_resp}" | jq '.' >&7
file_id=`echo "${file_create_resp}" | jq -r '.id'`

echo Get download url for file id: ${file_id} >&7
file_url_resp=$(dds_curl GET "/files/${file_id}/url")
echo "${file_url_resp}" | jq '.' >&7
download_data ${download_location} ${file_url_resp}

echo Get Upload info: ${upload_id} >&7
upload_get_resp=$(dds_curl GET "/uploads/${upload_id}")
echo "${upload_get_resp}" | jq '.' >&7
