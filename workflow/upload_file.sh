#!/bin/bash
workflow_dir=`dirname $0`
delay=0
declare -r DIR=$(cd "${workflow_dir}" && pwd)
source $DIR/restlib.sh

usage_and_exit()
{
  read -d '' usage << USAGE
usage: upload_file.sh [-hp] file_path parant_kind parent_id
  parent_kind: must be either 'project' or 'folder'
  parent_id: id of the parent into which file is to be uploaded. Parent must exist.
  -h display this message
  -v verbose output
  -p pretend mode, do not hit the server

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

verbose=false
pretend=false
while getopts ":hvp" opt; do
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

verbose_echo "Verbose output"
$pretend && verbose_echo "Running in pretend mode"

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

file=$1
if [ -z ${file} ]
then
  usage_and_exit 1
fi
if [ ! -f ${file} ]
then
  echo "${file} does not exist, or is not a regular file (no directories allowed.)"
  usage_and_exit 1
fi
file_name=`basename ${file}`
parent_kind=$2
case parent_kind in
  dds-project)
    ;;
  dds-folder)
    ;;
  \?)
    echo "Invalid parent_kind: ${parent_kind}" >&2
    ;;
esac
parent_id=$3
project_id="${parent_id}"
if [ "${parent_kind}" == "dds-folder" ]
then
  verbose_echo "getting project_id from parent"
  get_command "${dds_url}/api/v1/folders/${parent_id}"
  project_id=$(harvest_response '.project.id')
else
  verbose_echo "ensuring project existence"
  get_command "${dds_url}/api/v1/projects/${parent_id}"
fi

verbose_echo "uploading ${file_name} at ${file} to ${parent_kind} ${parent_id}"
upload_size=`wc -c ${file} | awk '{print $1}'`
upload_md5=`md5 ${file} | awk '{print $NF}'`
verbose_echo "creating upload in project ${project_id}"
crud_command 'POST' "${dds_url}/api/v1/projects/${project_id}/uploads" "{\"name\":\"${file_name}\",\"content_type\":\"text%2Fplain\",\"size\":\"${upload_size}\"}"
upload_id=$(harvest_response '.id')

number=1
verbose_echo "creating chunk ${number}"
crud_command 'PUT' "${dds_url}/api/v1/uploads/${upload_id}/chunks" "{\"number\":\"${number}\",\"size\":\"${upload_size}\",\"hash\":{\"value\":\"${upload_md5}\",\"algorithm\":\"md5\"}}"
host=$(harvest_response '.host')
put_url=$(harvest_response '.url')
verbose_echo "posting data to ${host}${put_url}"
$verbose && set -o verbose
download_verbosity="-s"
$verbose && download_verbosity="-v"
resp=`curl --insecure ${download_verbosity} -T ${file} "${host}${put_url}"`
if [ $? -gt 0 ]
then
 echo "Problem!"
 exit 1
fi
# $verbose && set +o verbose
verbose_echo "completing upload"
crud_command 'PUT' "${dds_url}/api/v1/uploads/${upload_id}/complete" "{\"hash\":{\"value\":\"${upload_md5}\",\"algorithm\":\"md5\"}}"

verbose_echo "creating file in ${parent_kind} ${parent_id}"
crud_command 'POST' "${dds_url}/api/v1/files" "{\"parent\":{\"kind\":\"${parent_kind}\",\"id\":\"${parent_id}\"},\"upload\":{\"id\":\"${upload_id}\"}}"
verbose_echo harvest_response '.id'
