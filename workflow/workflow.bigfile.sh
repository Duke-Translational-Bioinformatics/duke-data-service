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
  echo "usage: workflow.sh [auth_token] [path_to_file]"
  exit 1
fi
infile=$2
if [ -z ${infile} ]
then
  echo "usage: workflow.sh [auth_token] [path_to_file]"
  exit 1
fi
if [ ! -e ${infile} ]
then
  echo "${infile} does not exist!"
  exit 1
fi
original_filename=`basename ${infile}`
tmpdirname=`uuidgen`
tmpdir="/tmp/${tmpdirname}"
echo "creating ${tmpdir}"
mkdir ${tmpdir}
upload_size=`stat -f '%z' ${infile}`
upload_md5=`md5 ${infile} | awk '{print $NF}'`
cd ${tmpdir}
split -b 5m ${infile} chunk

dds_url=$DDSURL
if [ -z $dds_url ]
then
  dds_url=https://192.168.99.100:3001
fi

echo "creating project ${dds_url}"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"WorkflowProject","description":"ProjectWorkflow"}' "${dds_url}/api/v1/projects"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ! -n ${error} ]
then
  echo "Problem! ${error}"
  exit 1
fi
project_id=`echo ${resp} | jq -r '.id'`
project_kind=`echo ${resp} | jq -r '.kind'`
echo "creating upload"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"'${original_filename}'","content_type":"audio%2Fmpeg","size":"'${upload_size}'","hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/projects/${project_id}/uploads"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ! -n ${error} ]
then
  echo "Problem! ${error}"
  exit 1
fi

upload_id=`echo ${resp} | jq -r '.id'`
number=1
for chunk in `ls ${tmpdir}/chunk* | sort`
do
   md5=`md5 ${chunk} | awk '{print $NF}'`
   if [ $? -gt 0 ]
   then
     echo "Problem!"
     exit 1
   fi

   size=`wc -c ${chunk} | awk '{print $1}'`
   if [ $? -gt 0 ]
   then
     echo "Problem!"
     exit 1
   fi

   echo "creating chunk ${number}"
   resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${size}'","hash":{"value":"'${md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/uploads/${upload_id}/chunks"`
   if [ $? -gt 0 ]
   then
     echo "Problem!"
     exit 1
   fi
   echo "${resp}"
   echo ${resp} | jq
   error=`echo ${resp} | jq '.error'`
   if [ ! -n ${error} ]
   then
     echo "Problem! ${error}"
     exit 1
   fi
   ((number++))

   host=`echo ${resp} | jq -r '.host'`
   put_url=`echo ${resp} | jq -r '.url'`
   echo "posting data to ${host}${put_url}"
   resp=`curl --insecure -v -T ${chunk} "${host}${put_url}"`
   if [ $? -gt 0 ]
   then
     echo "Problem!"
     exit 1
   fi
done
echo "completing upload"
resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/uploads/${upload_id}/complete"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
error=`echo ${resp} | jq '.error'`
if [ ! -n ${error} ]
then
  echo "Problem! ${error}"
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
if [ ! -n ${error} ]
then
  echo "Problem! ${error}"
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
if [ ! -n ${error} ]
then
  echo "Problem! ${error}"
  exit 1
fi
host=`echo ${resp} | jq -r '.host'`
put_url_template=`echo ${resp} | jq -r '.url'`
put_url=`echo ${put_url_template} | awk -F '?' '{print $1}'`
temp_url_sig=`echo ${put_url_template} | awk -F '?' '{print $NF}' | awk -F'&' '{print $1}'`
temp_url_expires=`echo ${put_url_template} | awk -F '?' '{print $NF}' | awk -F'&' '{print $2}'`
echo "downloading FILE data from ${host}${put_url} ${temp_url_sig} ${temp_url_expires}"

echo "downloading file"
curl -G --data-urlencode "${temp_url_sig}" --data-urlencode "${temp_url_expires}" "${host}${put_url}" > ${tmpdir}/${original_filename}
echo "original md5: ${upload_md5} size: ${upload_size}"
download_md5=`md5 ${tmpdir}/${original_filename} | awk '{print $NF}'`
download_size=`stat -f '%z' ${tmpdir}/${original_filename}`
echo "download md5: ${download_md5} size: ${download_size}"
if [ ${download_size} == ${upload_size} ]
then
  if [ ${download_md5} == ${upload_md5} ]
  then
    echo "All CLEAR, cleaning up"
    rm -rf ${tmpdir}
  else
    echo "md5 does not match!"
    exit 1
  fi
else
  echo "size does not match"
  exit 1
fi
