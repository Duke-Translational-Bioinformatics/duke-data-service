#!/bin/bash
which jq > /dev/null
if [ $? -gt 0 ]
then
  echo "install jq https://stedolan.github.io/jq/"
  exit 1
fi

verbose_echo()
{
  $verbose && echo $1 >&2
}

crud_command()
{
  local crud_op=$1
  local url=$2
  local payload=$3
  verbose_echo "${crud_op} ${url} ${payload}"
  if ! $pretend
  then
    sleep $delay
    $verbose && set -o verbose
    curl_progress="s"
    $verbose && curl_progress="#"
    data_flag=""
    if [ "${payload}" == null ]
    then
      local payload=""
    else
      data_flag='-d'
    fi
    response=$(curl --insecure -${curl_progress} -X ${crud_op} --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: ${auth_token}" ${data_flag} "${payload}" "${url}")
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

post_command()
{
  local url=$1
  local payload=$2
  crud_command "POST" "${url}" "${payload}"
}

get_command()
{
  local url=$1
  crud_command "GET" "${url}"
}

get_id_from_response()
{
  harvest_response '.id'
}

harvest_response()
{
  local jq_input=$1
  if $pretend
  then
    echo "P-`uuidgen`"
  else
    echo ${response} | jq -r "${jq_input}"
  fi
}
