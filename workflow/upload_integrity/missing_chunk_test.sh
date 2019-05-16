#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Scenario: Client fails to register a chunk and reports the actual size of the file for the upload'
echo 'This can happen if the client just skips a chunk, or if the client reports chunk 1 as chunk 2, and then reports chunk 2 as chunk 2, which will overwrite the chunk 2 values reported for chunk 1.'

chunk_1_payload='{"number":"2","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'
echo "Chunk 1 payload: \`${chunk_1_payload}\`"
echo
echo "Chunk 2 payload: \`${chunk_2_payload}\`"
echo

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
