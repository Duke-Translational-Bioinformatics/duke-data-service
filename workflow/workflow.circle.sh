#!/bin/bash
which jq > /dev/null
if [ $? -gt 0 ]
then
  echo "install jq https://stedolan.github.io/jq/"
  exit 1
fi

auth_token=`grep MY_GENERATED_JWT dredd.env | awk -F'=' '{print $NF}'`
if [ -z ${auth_token} ]
then
  cat dredd.env
  exit 1
fi
if [ -z $DDSURL ]
then
  echo "DDSURL Environmet Variable Empty!"
  exit 1
fi

dds_url=$DDSURL

echo "creating project ${dds_url} ${auth_token}"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"DarinProject","description":"ProjectDarin"}' "${dds_url}/api/v1/projects"`
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
project_id=`echo ${resp} | jq -r '.id'`
project_kind=`echo ${resp} | jq -r '.kind'`
upload_size=`wc -c test_file.txt | awk '{print $1}'`
upload_md5=`md5sum test_file.txt | awk '{print $1}'`
echo "creating upload"
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"test_file.txt","content_type":"text%2Fplain","size":"'${upload_size}'","hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/projects/${project_id}/uploads"`
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
   resp=`curl -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${size}'","hash":{"value":"'${md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/uploads/${upload_id}/chunks"`
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
done
echo "completing upload"
resp=`curl -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/uploads/${upload_id}/complete"`
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
resp=`curl -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"parent":{"kind":"'${project_kind}'","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}' "${dds_url}/api/v1/files"`
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
curl -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/files/${file_id}" | jq
if [ $? -gt 0 ]
then
  echo "Problem!"
  exit 1
fi
echo "getting FILE ${file_id} download url:"
resp=`curl -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/files/${file_id}/url"`
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
