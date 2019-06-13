#!/bin/bash

./control_test.sh $1
./bad_upload_md5_test.sh $1
./missing_chunk_test.sh $1
./missing_chunk_and_bad_upload_size_test.sh $1
./chunks_out_of_order_test.sh $1
