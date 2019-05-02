# Common usage for upload integrity test scripts

usage() {
  echo "usage: $0 data_dir"
  echo 'Requires environment variables: DDS_URL DDS_AUTH_TOKEN DDS_PROJECT_ID'
  echo 'Verbose output is directed to file descriptor 7'
  exit 1
}
data_dir=$1
if [ -z ${data_dir} ]
then
  usage
fi
dds_url=$DDS_URL
if [ -z $dds_url ]
then
  usage
fi
auth_token=$DDS_AUTH_TOKEN
if [ -z $auth_token ]
then
  usage
fi
project_id=$DDS_PROJECT_ID
if [ -z $project_id ]
then
  usage
fi
