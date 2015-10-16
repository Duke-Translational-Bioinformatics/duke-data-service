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

dds_url=$DDSURL
if [ -z $dds_url ]
then
  dds_url=https://192.168.99.100
fi

echo "creating project ${dds_url}"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"DarinProject","description":"ProjectDarin"}' "${dds_url}:3001/api/v1/projects"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
project_id=`echo ${resp} | jq '.id' | sed 's/\"//g'`
upload_size=`wc -c test_file.txt | awk '{print $1}'`
upload_md5=`md5 test_file.txt | awk '{print $NF}'`
echo "creating upload"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"test_file.txt","content_type":"text%2Fplain","size":"'${upload_size}'","hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}:3001/api/v1/projects/${project_id}/uploads"`
if [ $? -gt 0 ]
then
  echo "Problem! ${resp}"
  exit 1
fi
echo ${resp} | jq
upload_id=`echo ${resp} | jq '.id' | sed 's/\"//g'`
for chunk in workflow/chunk*.txt
do
   md5=`md5 ${chunk} | awk '{print $NF}'`
   size=`wc -c ${chunk} | awk '{print $1}'`
   number=`echo ${chunk} | perl -pe 's/.*chunk(\d)\.txt/$1/'`
   echo "creating chunk ${number}"
   resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${size}'","hash":{"value":"'${md5}'","algorithm":"md5"}}' "${dds_url}:3001/api/v1/uploads/${upload_id}/chunks"`
   if [ $? -gt 0 ]
   then
     echo "Problem! ${resp}"
     exit 1
   fi
   echo ${resp} | jq
   host=`echo ${resp} | jq '.host' | sed 's/\"//g'`
   put_url=`echo ${resp} | jq '.url'| sed 's/\"//g'`
   echo "posting data"
   resp=`curl --insecure -v -T ${chunk} "${host}${put_url}"`
   if [ ! -z "${resp}" ]
   then
     echo "PROBLEM ${resp}"
     exit 1
   fi
done
echo "completing upload"
resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}:3001/api/v1/uploads/${upload_id}/complete"`
if [ $? -gt 0 ]
then
  echo "Problem! ${resp}"
  exit 1
fi
echo ${resp} | jq
echo "creating file"
resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"upload":{"id":"'${upload_id}'"}}' "${dds_url}:3001/api/v1/projects/${project_id}/files"`
if [ $? -gt 0 ]
then
  echo "Problem! ${resp}"
  exit 1
fi
echo ${resp} | jq
file_id=`echo $resp | jq '.id' | sed 's/\"//g'`
curl --insecure -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}:3001/api/v1/files/${file_id}" | jq
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
curl --insecure -# -L --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}:3001/api/v1/files/${file_id}/download"
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
