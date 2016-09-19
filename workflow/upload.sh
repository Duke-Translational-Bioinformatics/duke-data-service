#!/bin/bash
which jq > /dev/null
if [ $? -gt 0 ]
then
  echo "install jq https://stedolan.github.io/jq/"
  exit 1
fi
auth_token=$1
if [ -z ${auth_token} ]
then
  echo "usage: workflow.sh auth_token project_id file"
  exit 1
fi
project_id=$2
if [ -z ${project_id} ]
then
  echo "usage: workflow.sh auth_token project_id file"
  exit 1
fi
file=$3
if [ -z ${project_id} ]
then
  echo "usage: workflow.sh auth_token project_id file"
  exit 1
fi
file_name=`basename ${file}`
echo "uploading ${file_name} at ${file} to project ${project_id}"

dds_url=$DDSURL
if [ -z $dds_url ]
then
  dds_url=http://localhost:3001
fi

project_kind='dds-project'
upload_size=`wc -c ${file} | awk '{print $1}'`
upload_md5=`md5 ${file} | awk '{print $NF}'`
echo "creating upload"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"'${file_name}'","content_type":"text%2Fplain","size":"'${upload_size}'"}' "${dds_url}/api/v1/projects/${project_id}/uploads"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ${error} != null ]
then
  echo "Problem!"
  exit 1
fi

upload_id=`echo ${resp} | jq -r '.id'`
number=1
echo "creating chunk ${number}"
resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${upload_size}'","hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/uploads/${upload_id}/chunks"`
if [ $? -gt 0 ]
then
 echo "Problem!"
 exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ${error} != null ]
then
 echo "Problem!"
 exit 1
fi

host=`echo ${resp} | jq -r '.host'`
put_url=`echo ${resp} | jq -r '.url'`
echo "posting data to ${host}${put_url}"
resp=`curl --insecure -v -T ${file} "${host}${put_url}"`
if [ $? -gt 0 ]
then
 echo "Problem!"
 exit 1
fi
echo "completing upload"
resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/uploads/${upload_id}/complete"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ${error} != null ]
then
  echo "Problem!"
  exit 1
fi

echo "creating file"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"parent":{"kind":"'${project_kind}'","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}' "${dds_url}/api/v1/files"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp}
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ${error} != null ]
then
  echo "Problem!"
  exit 1
fi
file_id=`echo ${resp} | jq -r '.id'`
echo "FILE ${file_id} Created:"
curl --insecure -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/files/${file_id}" | jq
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo "getting FILE ${file_id} download url:"
resp=`curl --insecure -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/files/${file_id}/url"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ${error} != null ]
then
  echo "Problem!"
  exit 1
fi
host=`echo ${resp} | jq -r '.host'`
put_url_template=`echo ${resp} | jq -r '.url'`
put_url=`echo ${put_url_template} | awk -F '?' '{print $1}'`
temp_url_sig=`echo ${put_url_template} | awk -F '?' '{print $NF}' | awk -F'&' '{print $1}'`
temp_url_expires=`echo ${put_url_template} | awk -F '?' '{print $NF}' | awk -F'&' '{print $2}'`
echo "downloading FILE data from ${host}${put_url} ${temp_url_sig} ${temp_url_expires}"
curl -G --data-urlencode "${temp_url_sig}" --data-urlencode "${temp_url_expires}" "${host}${put_url}"
