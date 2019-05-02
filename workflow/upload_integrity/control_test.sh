#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Upload without errors'
echo 'This is the baseline run. Sizes, hashes, and chunk order are all inline with the test file.'
echo
echo "Upload create payload: \`${upload_create_payload}\`"
echo
echo "Chunk 1 payload: \`${chunk_1_payload}\`"
echo
echo "Chunk 2 payload: \`${chunk_2_payload}\`"
echo
echo "Chunk 3 payload: \`${chunk_3_payload}\`"
echo
echo "Chunk 4 payload: \`${chunk_4_payload}\`"
echo
echo "Complete Upload payload: \`${upload_complete_payload}\`"

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
