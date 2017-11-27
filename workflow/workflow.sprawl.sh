#!/bin/bash
workflow_dir=`dirname $0`
declare -r DIR=$(cd "${workflow_dir}" && pwd)
source $DIR/restlib.sh

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
echo "Created `echo $folder_total | bc` folders in project ${project_id}"
