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
echo "creating project"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"DarinProject","description":"ProjectDarin"}' "http://192.168.99.100:3001/api/v1/projects"`
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo ${resp} | jq
project_id=`echo ${resp} | jq -r '.id'`
project_kind=`echo ${resp} | jq -r '.kind'`
upload_size=`wc -c test_file.txt | awk '{print $1}'`
upload_md5=`md5 test_file.txt | awk '{print $NF}'`
echo "creating upload"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"test_file.txt","content_type":"text%2Fplain","size":"'${upload_size}'","hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "http://192.168.99.100:3001/api/v1/projects/${project_id}/uploads"`
if [ $? -gt 0 ]
then
  echo "Problem! ${resp}"
  exit 1
fi
echo ${resp} | jq
upload_id=`echo ${resp} | jq -r '.id'`
for chunk in chunk*.txt
do
   md5=`md5 ${chunk} | awk '{print $NF}'`
   size=`wc -c ${chunk} | awk '{print $1}'`
   number=`echo ${chunk} | perl -pe 's/chunk(\d)\.txt/$1/'`
   echo "creating chunk ${number}"
   resp=`curl -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${size}'","hash":{"value":"'${md5}'","algorithm":"md5"}}' "http://192.168.99.100:3001/api/v1/uploads/${upload_id}/chunks"`
   if [ $? -gt 0 ]
   then
     echo "Problem! ${resp}"
     exit 1
   fi
   echo ${resp} | jq
   host=`echo ${resp} | jq -r '.host'`
   put_url=`echo ${resp} | jq -r '.url'`
   echo "posting data"
   curl -v -T ${chunk} "${host}${put_url}"
   if [ $? -gt 0 ]
   then
     echo "Problem!"
     exit 1
   fi
done
echo "completing upload"
resp=`curl -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "http://192.168.99.100:3001/api/v1/uploads/${upload_id}/complete"`
if [ $? -gt 0 ]
then
  echo "Problem! ${resp}"
  exit 1
fi
echo ${resp} | jq
echo "creating file"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"parent":{"kind":"'${project_kind}'","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}' "http://192.168.99.100:3001/api/v1/files"`
if [ $? -gt 0 ]
then
  echo "Problem! ${resp}"
  exit 1
fi
echo ${resp} | jq
file_id=`echo $resp | jq -r '.id'`
echo "FILE ${file_id} Created:"
curl -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "http://192.168.99.100:3001/api/v1/files/${file_id}" | jq
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo "FILE ${file_id} download:"
curl -# -L --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "http://192.168.99.100:3001/api/v1/files/${file_id}/download"
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
