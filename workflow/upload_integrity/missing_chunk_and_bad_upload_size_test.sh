#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Upload missing chunk 1 and size calculated from chunks 2-4'

chunk_1_payload='{"number":"2","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'
echo "Chunk 1 payload: \`${chunk_1_payload}\`"
echo '(This chunk will be overwritten when Chunk 2 is submitted.)'

bad_upload_size=$((chunk_2_size + chunk_3_size + chunk_4_size))
upload_create_payload='{"name":"'${upload_file_name}'","content_type":"text%2Fplain","size":"'${bad_upload_size}'"}'
echo "Upload create payload: \`${upload_create_payload}\`"

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
