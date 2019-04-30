#!/bin/bash
which jq > /dev/null
if [ $? -gt 0 ]
then
  echo "install jq https://stedolan.github.io/jq/"
  exit 1
fi

usage() {
  echo "usage: $0 data_dir"
  echo 'Requires environment variables: DDS_URL DDS_AUTH_TOKEN DDS_PROJECT_ID'
  exit 1
}
data_dir=$1
if [ -z ${data_dir} ]
then
  usage
fi
dds_url=$DDS_URL
if [ -z $dds_url ]
then
  usage
fi
auth_token=$DDS_AUTH_TOKEN
if [ -z $auth_token ]
then
  usage
fi
project_id=$DDS_PROJECT_ID
if [ -z $project_id ]
then
  usage
fi

# Chunk 1 variables
chunk_1_location="${data_dir}/chunk1.txt"
chunk_1_size=`wc -c ${chunk_1_location} | cut -f1 -d' '`
chunk_1_md5=`md5sum ${chunk_1_location} | cut -f1 -d' '`
chunk_1_payload='{"number":"1","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'

# Chunk 2 variables
chunk_2_location="${data_dir}/chunk2.txt"
chunk_2_size=`wc -c ${chunk_2_location} | cut -f1 -d' '`
chunk_2_md5=`md5sum ${chunk_2_location} | cut -f1 -d' '`
chunk_2_payload='{"number":"2","size":"'${chunk_2_size}'","hash":{"value":"'${chunk_2_md5}'","algorithm":"md5"}}'

# Chunk 3 variables
chunk_3_location="${data_dir}/chunk3.txt"
chunk_3_size=`wc -c ${chunk_3_location} | cut -f1 -d' '`
chunk_3_md5=`md5sum ${chunk_3_location} | cut -f1 -d' '`
chunk_3_payload='{"number":"3","size":"'${chunk_3_size}'","hash":{"value":"'${chunk_3_md5}'","algorithm":"md5"}}'

# Chunk 4 variables
chunk_4_location="${data_dir}/chunk4.txt"
chunk_4_size=`wc -c ${chunk_4_location} | cut -f1 -d' '`
chunk_4_md5=`md5sum ${chunk_4_location} | cut -f1 -d' '`
chunk_4_payload='{"number":"4","size":"'${chunk_4_size}'","hash":{"value":"'${chunk_4_md5}'","algorithm":"md5"}}'

# Chunk 4 variables
upload_file_name="test_file.txt"
upload_location="${data_dir}/test_file.txt"
upload_size=`wc -c ${upload_location} | cut -f1 -d' '`
upload_md5=`md5sum ${upload_location} | cut -f1 -d' '`
upload_create_payload='{"name":"'${upload_file_name}'","content_type":"text%2Fplain","size":"'${upload_size}'"}'
upload_complete_payload='{"hash":{"value":"'${upload_md5}'","algorithm":"md5"}}'

echo ${chunk_1_payload}
echo ${chunk_2_payload}
echo ${chunk_3_payload}
echo ${chunk_4_payload}
echo ${upload_complete_payload}

dds_curl() {
  unset success
  until [ "${success}" = "yes" ]; do
    if [ -z $3 ]
    then
      curl_resp=`curl -k -s -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: ${auth_token}" -X $1 "${dds_url}/api/v1/$2"`
    else
      curl_resp=`curl -k -s -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: ${auth_token}" -X $1 -d $3 "${dds_url}/api/v1/$2"`
    fi
    if [ $? -gt 0 ]
    then
      echo "Problem!" >&2
      exit 1
    fi
    error=`echo ${curl_resp} | jq '.error'`
    if [ ${error} = null ]
    then
      echo ${curl_resp} # | jq
      success='yes'
    else
      error_code=`echo ${curl_resp} | jq '.code'`
      echo "error_code = ${error_code}" >&2
      if [ "${error_code}" = '"resource_not_consistent"' ]
      then
        echo 'waiting...' >&2
        sleep 1
      else
        echo ${curl_resp} | jq >&2
        echo "Problem!" >&2
        exit 1
      fi
    fi
  done
}

upload_data() {
  file=$1
  host=`echo $2 | jq -r '.host'`
  put_url=`echo $2 | jq -r '.url'`
  echo "Uploading data from ${file} to ${host}${put_url}"
  curl -k -s -T ${file} "${host}${put_url}"
}

echo Create upload with: ${upload_create_payload}
resp=$(dds_curl POST "/projects/${project_id}/uploads" ${upload_create_payload})
echo ${resp} | jq

upload_id=`echo ${resp} | jq -r '.id'`

echo Create chunk_1 with: ${chunk_1_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_1_payload})
echo ${resp} | jq
upload_data ${chunk_1_location} ${resp}

echo Create chunk_2 with: ${chunk_2_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_2_payload})
echo ${resp} | jq
upload_data ${chunk_2_location} ${resp}

echo Create chunk_3 with: ${chunk_3_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_3_payload})
echo ${resp} | jq
upload_data ${chunk_3_location} ${resp}

echo Create chunk_4 with: ${chunk_4_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/chunks" ${chunk_4_payload})
echo ${resp} | jq
upload_data ${chunk_4_location} ${resp}

echo Complete upload with: ${upload_complete_payload}
resp=$(dds_curl PUT "/uploads/${upload_id}/complete" ${upload_complete_payload})
echo ${resp} | jq

file_create_payload='{"parent":{"kind":"dds-project","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}'
echo Complete upload with: ${file_create_payload}
resp=$(dds_curl POST "/files" ${file_create_payload})
echo ${resp} | jq
file_id=`echo ${resp} | jq -r '.id'`

echo Get download url for file id: ${file_id}
resp=$(dds_curl GET "/files/${file_id}/url")
echo ${resp} | jq

