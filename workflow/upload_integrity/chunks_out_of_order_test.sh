#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Scenario: Client registers the chunks in the wrong order'

chunk_1_payload='{"number":"5","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'
chunk_2_payload='{"number":"6","size":"'${chunk_2_size}'","hash":{"value":"'${chunk_2_md5}'","algorithm":"md5"}}'
echo "Chunk 1 payload: \`${chunk_1_payload}\`"
echo
echo "Chunk 2 payload: \`${chunk_2_payload}\`"
echo
echo "Chunk 3 payload: \`${chunk_3_payload}\`"
echo
echo "Chunk 4 payload: \`${chunk_4_payload}\`"
echo

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
