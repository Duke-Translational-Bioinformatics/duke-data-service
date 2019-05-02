#!/bin/bash

source includes/curl_functions.sh
source includes/integrity_functions.sh
source includes/common_usage.sh
source includes/default_variables.sh

echo '# Upload without errors'

source includes/run_upload_workflow.sh

show_test_results "${upload_get_resp}" "${download_location}"
