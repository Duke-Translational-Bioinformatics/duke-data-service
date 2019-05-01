# Functions for checking data integrity

chunk_md5sum() {
  chunk=$1
  input_file=$2
  chunk_number=$(echo "${chunk}" | jq -r '.number')
  chunk_size=$(echo "${chunk}1" | jq -r '.size')
  dd skip=${offset} count=${chunk_size} if=${input_file} of=/dev/stdout bs=1 status=none | md5sum | cut -f1 -d' '
}
