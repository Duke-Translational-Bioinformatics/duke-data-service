#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Upload missing chunk 1'

chunk_1_payload='{"number":"2","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'
echo "Chunk 1 payload: ${chunk_1_payload}"
echo '(This chunk will be overwritten when Chunk 2 is submitted.)'

source includes/run_upload_workflow.sh

echo "${upload_get_resp}" | jq '.status'
test_chunks_table "${upload_get_resp}" "${download_location}"
test_file_table "${upload_get_resp}" "${download_location}"
