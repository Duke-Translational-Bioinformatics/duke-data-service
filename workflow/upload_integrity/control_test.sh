#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Upload without errors'

source includes/run_upload_workflow.sh

echo "${upload_get_resp}" | jq '.status'
test_chunks_table "${upload_get_resp}" "${download_location}"
test_file_table "${upload_get_resp}" "${download_location}"
