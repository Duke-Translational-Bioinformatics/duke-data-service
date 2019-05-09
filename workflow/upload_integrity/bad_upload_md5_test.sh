#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Scenario: Client reports an incorrect MD5 that does not match the actual MD5 of the file being uploaded'

upload_complete_payload='{"hash":{"value":"thisisabadmd5yo","algorithm":"md5"}}'
echo "Complete Upload payload: \`${upload_complete_payload}\`"
echo

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
