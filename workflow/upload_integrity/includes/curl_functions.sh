# Curl functions for DDS
which jq > /dev/null
if [ $? -gt 0 ]
then
  echo "install jq https://stedolan.github.io/jq/"
  exit 1
fi

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
      echo "Curl error. ${curl_resp}" >&2
      exit 1
    fi
    error=`echo "${curl_resp}" | jq '.error'`
    if [ ${error} = null ]
    then
      echo "${curl_resp}"
      success='yes'
    else
      error_code=`echo ${curl_resp} | jq '.code'`
      echo "error_code = ${error_code}" >&2
      if [ "${error_code}" = '"resource_not_consistent"' ]
      then
        echo 'waiting...' >&2
        sleep 1
      else
        echo "${curl_resp}"
        exit 1
      fi
    fi
  done
}

upload_data() {
  file=$1
  host=`echo $2 | jq -r '.host'`
  put_url=`echo $2 | jq -r '.url'`
  echo "Uploading data from ${file} to ${host}${put_url}" >&2
  curl -k -s -T ${file} "${host}${put_url}"
}

download_data() {
  file=$1
  host=`echo $2 | jq -r '.host'`
  put_url=`echo $2 | jq -r '.url'`
  echo "Downloading data from ${host}${put_url} to ${file}" >&2
  curl -k -s -o ${file} "${host}${put_url}"
}
