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
  echo "usage: workflow.sh [auth_token]"
  exit 1
fi
if [ -z $DDSURL ]
then
  echo "DDSURL Environmet Variable Empty!"
  exit 1
fi

dds_url=$DDSURL

echo "creating project ${dds_url}"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"DarinProject","description":"ProjectDarin"}' "${dds_url}:3001/api/v1/projects"`
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
project_id=`echo ${resp} | jq -r '.id'`
project_kind=`echo ${resp} | jq -r '.kind'`
upload_size=`wc -c test_file.txt | awk '{print $1}'`
upload_md5=`md5sum test_file.txt | awk '{print $1}'`
echo "creating upload"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"test_file.txt","content_type":"text%2Fplain","size":"'${upload_size}'","hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}:3001/api/v1/projects/${project_id}/uploads"`
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
for chunk in workflow/chunk*.txt
do
   md5=`md5sum ${chunk} | awk '{print $1}'`
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

   number=`echo ${chunk} | perl -pe 's/.*chunk(\d)\.txt/$1/'`
   echo "creating chunk ${number}"
   resp=`curl -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${size}'","hash":{"value":"'${md5}'","algorithm":"md5"}}' "${dds_url}:3001/api/v1/uploads/${upload_id}/chunks"`
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
   curl -v -T ${chunk} "${host}${put_url}"
   if [ $? -gt 0 ]
   then
     echo "Problem!"
     exit 1
   fi
   if [ ! -z "${resp}" ]
   then
     echo "PROBLEM ${resp}"
     exit 1
   fi
done
echo "completing upload"
resp=`curl -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}:3001/api/v1/uploads/${upload_id}/complete"`
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
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"parent":{"kind":"'${project_kind}'","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}' "4{dds_url}:3001/api/v1/files"`
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
file_id=`echo $resp | jq -r '.id'`
echo "FILE ${file_id} Created:"
curl -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}:3001/api/v1/files/${file_id}" | jq
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
echo "FILE ${file_id} download:"
curl -# -L --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}:3001/api/v1/files/${file_id}/download"
