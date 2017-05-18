#!/bin/bash
which jq > /dev/null
if [ $? -gt 0 ]
then
  echo "install jq https://stedolan.github.io/jq/"
  exit 1
fi

max_folder_name_count=6

usage_and_exit()
{
  read -d '' usage << USAGE
usage: workflow.sprawl.sh [-hvp] [-d seconds] folder_name ...
  -h display this message
  -v verbose output
  -p pretend mode, do not hit the server
  -f force script to run when more than ${max_folder_name_count} folder_names are provided
  -d delay (in seconds) between server calls. (default: 1)

Requires DDSTOKEN to be set to a valid api token and DDSURL to be
set to the appropriate api url.
USAGE
  if [ -n "$1" ] && [ $1 -gt 0 ]
  then
    echo "${usage}" >&2
    exit $1
  else
    echo "${usage}"
    exit 0
  fi
}

verbose_echo()
{
  $verbose && echo $1 >&2
}

post_command()
{
  local url=$1
  local payload=$2
  verbose_echo "post_command $url $payload"
  if ! $pretend
  then
    sleep $delay
    $verbose && set -o verbose
    curl_progress="s"
    $verbose && curl_progress="#"
    response=$(curl --insecure -${curl_progress} -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: ${auth_token}" -d "${payload}" "${url}")
    if [ $? -gt 0 ]
    then
      echo "Problem!"
      exit 1
    fi
    $verbose && set +o verbose
    $verbose && echo ${response} | jq
    error=`echo ${response} | jq '.error'`
    if [ "${error}" != null ]
    then
      echo "Problem!"
      exit 1
    fi
  fi
}

get_id_from_response()
{
  local response_id=''
  if $pretend
  then
    response_id="P-`uuidgen`"
  else
    response_id=`echo ${response} | jq -r '.id'`
  fi
  echo $response_id
}

build_folders()
{
  local parent_id=$1
  local parent_kind=$2
  shift 2
  if [ $# -gt 0 ]
    local child_folders=( "$@" )
    then
    for child in "${child_folders[@]}"
    do
      post_command "${dds_url}/api/v1/folders" "{\"parent\": {\"id\": \"${parent_id}\", \"kind\":\"${parent_kind}\"}, \"name\":\"${child}\"}"
      folder_total=$folder_total+1
      local child_id=$(get_id_from_response) #`echo ${response} | jq -r '.id'`
      #echo "build_folder: ${parent_id}[${parent_kind}]/${child}, id: ${child_id}"
      children="${child_folders[@]}"
      build_folders $child_id "dds-folder" "${children[@]/$child}"
    done
  fi
}

verbose=false
pretend=false
force=false
delay=1
while getopts ":hvpfd:" opt; do
  case $opt in
    h)
      usage_and_exit
      ;;
    v)
      verbose=true
      ;;
    p)
      pretend=true
      ;;
    f)
      force=true
      ;;
    d)
      if [ "$OPTARG" -ge 0 ]
      then
        delay=$OPTARG
      else
        echo "Delay must be a positive integer" >&2
        exit 1
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Shift options off parameters
shift $((OPTIND-1))

folders=( "$@" )
if [ $# -lt 1 ]
then
  usage_and_exit 1
elif [ $# -gt $max_folder_name_count ] && ! $force
then
  echo "Too many folder_names, ${max_folder_name_count} is the max." >&2
  usage_and_exit 1
fi

verbose_echo "Verbose output"
$pretend && verbose_echo "Running in pretend mode"
verbose_echo "Delay set to $delay"

auth_token=$DDSTOKEN
if [ -z ${auth_token} ]
then
  echo "DDSTOKEN is empty."
  exit 1
fi
verbose_echo "Using token: [${auth_token}]"

dds_url=$DDSURL
if [ -z $dds_url ]
then
  echo "DDSURL is empty."
  exit 1
fi
verbose_echo "Using url: [${dds_url}]"

project_name="Sprawl `date "+%Y%m%d%H%M%S"`"
project_desc="Project created by workflow.sprawl.sh on `date`"
verbose_echo "Creating project '${project_name}' at ${dds_url}"
post_command "${dds_url}/api/v1/projects" "{\"name\":\"${project_name}\",\"description\":\"${project_desc}\"}"
project_id=$(get_id_from_response) #`uuidgen` #`echo ${response} | jq -r '.id'`

folder_total=0
build_folders $project_id "dds-project" "${folders[@]}"
echo "Created `echo $folder_total | bc` folders"

#for folder in "${folders[@]}"
#do
#  echo $folder
#  echo "${folders[@]/$folder}"
#done

#project_kind=`echo ${resp} | jq -r '.kind'`
#upload_size=`wc -c test_file.txt | awk '{print $1}'`
#upload_md5=`md5 test_file.txt | awk '{print $NF}'`
#echo "creating upload"
#resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"name":"test_file.txt","content_type":"text%2Fplain","size":"'${upload_size}'"}' "${dds_url}/api/v1/projects/${project_id}/uploads"`
#if [ $? -gt 0 ]
#then
#  echo "Problem!"
#  exit 1
#fi
#echo ${resp} | jq
#error=`echo ${resp} | jq '.error'`
#if [ ${error} != null ]
#then
#  echo "Problem!"
#  exit 1
#fi
#
#upload_id=`echo ${resp} | jq -r '.id'`
#for chunk in workflow/chunk*.txt
#do
#   md5=`md5 ${chunk} | awk '{print $NF}'`
#   if [ $? -gt 0 ]
#   then
#     echo "Problem!"
#     exit 1
#   fi
#
#   size=`wc -c ${chunk} | awk '{print $1}'`
#   if [ $? -gt 0 ]
#   then
#     echo "Problem!"
#     exit 1
#   fi
#
#   number=`echo ${chunk} | perl -pe 's/.*chunk(\d)\.txt/$1/'`
#   echo "creating chunk ${number}"
#   resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"number":"'${number}'","size":"'${size}'","hash":{"value":"'${md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/uploads/${upload_id}/chunks"`
#   if [ $? -gt 0 ]
#   then
#     echo "Problem!"
#     exit 1
#   fi
#   echo ${resp} | jq
#   error=`echo ${resp} | jq '.error'`
#   if [ ${error} != null ]
#   then
#     echo "Problem!"
#     exit 1
#   fi
#
#   host=`echo ${resp} | jq -r '.host'`
#   put_url=`echo ${resp} | jq -r '.url'`
#   echo "posting data to ${host}${put_url}"
#   resp=`curl --insecure -v -T ${chunk} "${host}${put_url}"`
#   if [ $? -gt 0 ]
#   then
#     echo "Problem!"
#     exit 1
#   fi
#done
#echo "completing upload"
#resp=`curl --insecure -# -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"hash":{"value":"'${upload_md5}'","algorithm":"md5"}}' "${dds_url}/api/v1/uploads/${upload_id}/complete"`
#if [ $? -gt 0 ]
#then
#  echo "Problem!"
#  exit 1
#fi
#echo ${resp} | jq
#error=`echo ${resp} | jq '.error'`
#if [ ${error} != null ]
#then
#  echo "Problem!"
#  exit 1
#fi
#
#echo "creating file"
#resp=`curl --insecure -# -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" -d '{"parent":{"kind":"'${project_kind}'","id":"'${project_id}'"},"upload":{"id":"'${upload_id}'"}}' "${dds_url}/api/v1/files"`
#if [ $? -gt 0 ]
#then
#  echo "Problem!"
#  exit 1
#fi
#echo ${resp}
#echo ${resp} | jq
#error=`echo ${resp} | jq '.error'`
#if [ ${error} != null ]
#then
#  echo "Problem!"
#  exit 1
#fi
#file_id=`echo ${resp} | jq -r '.id'`
#echo "FILE ${file_id} Created:"
#curl --insecure -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/files/${file_id}" | jq
#if [ $? -gt 0 ]
#then
#  echo "Problem!"
#  exit 1
#fi
#echo "getting FILE ${file_id} download url:"
#resp=`curl --insecure -# --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${auth_token}" "${dds_url}/api/v1/files/${file_id}/url"`
#if [ $? -gt 0 ]
#then
#  echo "Problem!"
#  exit 1
#fi
#echo ${resp} | jq
#error=`echo ${resp} | jq '.error'`
#if [ ${error} != null ]
#then
#  echo "Problem!"
#  exit 1
#fi
#host=`echo ${resp} | jq -r '.host'`
#put_url_template=`echo ${resp} | jq -r '.url'`
#put_url=`echo ${put_url_template} | awk -F '?' '{print $1}'`
#temp_url_sig=`echo ${put_url_template} | awk -F '?' '{print $NF}' | awk -F'&' '{print $1}'`
#temp_url_expires=`echo ${put_url_template} | awk -F '?' '{print $NF}' | awk -F'&' '{print $2}'`
#echo "downloading FILE data from ${host}${put_url} ${temp_url_sig} ${temp_url_expires}"
#curl -G --data-urlencode "${temp_url_sig}" --data-urlencode "${temp_url_expires}" "${host}${put_url}"
