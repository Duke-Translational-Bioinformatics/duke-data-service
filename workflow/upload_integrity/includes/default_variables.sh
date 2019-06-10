# Script variables
script_name=`basename $0`
test_name=`echo $script_name | cut -d. -f1`

# Chunk 1 variables
chunk_1_location="${data_dir}/chunk1.txt"
chunk_1_size=`wc -c ${chunk_1_location} | cut -f1 -d' '`
chunk_1_md5=`md5sum ${chunk_1_location} | cut -f1 -d' '`
chunk_1_payload='{"number":"1","size":"'${chunk_1_size}'","hash":{"value":"'${chunk_1_md5}'","algorithm":"md5"}}'

# Chunk 2 variables
chunk_2_location="${data_dir}/chunk2.txt"
chunk_2_size=`wc -c ${chunk_2_location} | cut -f1 -d' '`
chunk_2_md5=`md5sum ${chunk_2_location} | cut -f1 -d' '`
chunk_2_payload='{"number":"2","size":"'${chunk_2_size}'","hash":{"value":"'${chunk_2_md5}'","algorithm":"md5"}}'

# Chunk 3 variables
chunk_3_location="${data_dir}/chunk3.txt"
chunk_3_size=`wc -c ${chunk_3_location} | cut -f1 -d' '`
chunk_3_md5=`md5sum ${chunk_3_location} | cut -f1 -d' '`
chunk_3_payload='{"number":"3","size":"'${chunk_3_size}'","hash":{"value":"'${chunk_3_md5}'","algorithm":"md5"}}'

# Chunk 4 variables
chunk_4_location="${data_dir}/chunk4.txt"
chunk_4_size=`wc -c ${chunk_4_location} | cut -f1 -d' '`
chunk_4_md5=`md5sum ${chunk_4_location} | cut -f1 -d' '`
chunk_4_payload='{"number":"4","size":"'${chunk_4_size}'","hash":{"value":"'${chunk_4_md5}'","algorithm":"md5"}}'

# Upload variables
upload_file_name="test_file.txt"
upload_location="${data_dir}/test_file.txt"
upload_size=`wc -c ${upload_location} | cut -f1 -d' '`
upload_md5=`md5sum ${upload_location} | cut -f1 -d' '`
upload_create_payload='{"name":"'${upload_file_name}'","content_type":"text%2Fplain","size":"'${upload_size}'"}'
upload_complete_payload='{"hash":{"value":"'${upload_md5}'","algorithm":"md5"}}'

# Download variables
download_location=`mktemp /tmp/${test_name}_XXXXXX.txt`
