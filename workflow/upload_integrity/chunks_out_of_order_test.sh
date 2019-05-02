#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Upload chunks are out of order'

chunk_1_payload='{"number":"5","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'
chunk_2_payload='{"number":"6","size":"'${chunk_2_size}'","hash":{"value":"'${chunk_2_md5}'","algorithm":"md5"}}'
echo "Chunk 1 payload: \`${chunk_1_payload}\`"
echo "Chunk 2 payload: \`${chunk_2_payload}\`"

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
