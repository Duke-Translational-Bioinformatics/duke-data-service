# Upload without errors
This is the baseline run. Sizes, hashes, and chunk order are all inline with the test file.

Upload create payload: `{"name":"test_file.txt","content_type":"text%2Fplain","size":"15"}`

Chunk 1 payload: `{"number":"1","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`

Chunk 2 payload: `{"number":"2","size":"3","hash":{"value":"7c0c0577834d29be479910502833588a","algorithm":"md5"}}`

Chunk 3 payload: `{"number":"3","size":"2","hash":{"value":"bf072e9119077b4e76437a93986787ef","algorithm":"md5"}}`

Chunk 4 payload: `{"number":"4","size":"5","hash":{"value":"2debfdcf79f03e4a65a667d21ef9de14","algorithm":"md5"}}`

Complete Upload payload: `{"hash":{"value":"19af6b658424206d13f90ccd9b49fadf","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-03T19:04:33.500Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-03T19:04:45.585Z",
  "is_consistent": true,
  "purged_on": null,
  "error_on": null,
  "error_message": null
}
```
### Test chunks

Chunk #	| Size  | Expected MD5                     | Actual MD5
-------	| ----- | ------------                     | ----------
1	| 5	| 8f99594aa44f8617fa505d20f3d32ec2 | 8f99594aa44f8617fa505d20f3d32ec2
2	| 3	| 7c0c0577834d29be479910502833588a | 7c0c0577834d29be479910502833588a
3	| 2	| bf072e9119077b4e76437a93986787ef | bf072e9119077b4e76437a93986787ef
4	| 5	| 2debfdcf79f03e4a65a667d21ef9de14 | 2debfdcf79f03e4a65a667d21ef9de14

### Test total file

.        | Size	| MD5
-------- | ----	| ---
Expected | 15	| 19af6b658424206d13f90ccd9b49fadf
Actual   | 15	| 19af6b658424206d13f90ccd9b49fadf

### Contents of downloaded file
```
THIS
IS
A
TEST
```
# Bad Upload MD5
Complete Upload payload: `{"hash":{"value":"thisisabadmd5yo","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-03T19:04:55.196Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-03T19:05:04.039Z",
  "is_consistent": true,
  "purged_on": null,
  "error_on": null,
  "error_message": null
}
```
### Test chunks

Chunk #	| Size  | Expected MD5                     | Actual MD5
-------	| ----- | ------------                     | ----------
1	| 5	| 8f99594aa44f8617fa505d20f3d32ec2 | 8f99594aa44f8617fa505d20f3d32ec2
2	| 3	| 7c0c0577834d29be479910502833588a | 7c0c0577834d29be479910502833588a
3	| 2	| bf072e9119077b4e76437a93986787ef | bf072e9119077b4e76437a93986787ef
4	| 5	| 2debfdcf79f03e4a65a667d21ef9de14 | 2debfdcf79f03e4a65a667d21ef9de14

### Test total file

.        | Size	| MD5
-------- | ----	| ---
Expected | 15	| thisisabadmd5yo
Actual   | 15	| 19af6b658424206d13f90ccd9b49fadf

### Contents of downloaded file
```
THIS
IS
A
TEST
```
# Upload missing chunk 1
Chunk 1 payload: `{"number":"2","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`
(This chunk will be overwritten when Chunk 2 is submitted.)
## Results
### Upload status
```
{
  "initiated_on": "2019-05-03T19:05:13.266Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-03T19:05:16.659Z",
  "is_consistent": true,
  "purged_on": null,
  "error_on": "2019-05-03T19:05:16.896Z",
  "error_message": "reported size does not match size computed by StorageProvider"
}
```
### Test chunks

Chunk #	| Size  | Expected MD5                     | Actual MD5
-------	| ----- | ------------                     | ----------
2	| 3	| 7c0c0577834d29be479910502833588a | d41d8cd98f00b204e9800998ecf8427e
3	| 2	| bf072e9119077b4e76437a93986787ef | d41d8cd98f00b204e9800998ecf8427e
4	| 5	| 2debfdcf79f03e4a65a667d21ef9de14 | d41d8cd98f00b204e9800998ecf8427e

### Test total file

.        | Size	| MD5
-------- | ----	| ---
Expected | 15	| 19af6b658424206d13f90ccd9b49fadf
Actual   | 0	| d41d8cd98f00b204e9800998ecf8427e

### Contents of downloaded file
```
```
# Upload missing chunk 1 and size calculated from chunks 2-4
Chunk 1 payload: `{"number":"2","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`
(This chunk will be overwritten when Chunk 2 is submitted.)
Upload create payload: `{"name":"test_file.txt","content_type":"text%2Fplain","size":"10"}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-03T19:05:25.870Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-03T19:05:28.485Z",
  "is_consistent": true,
  "purged_on": null,
  "error_on": null,
  "error_message": null
}
```
### Test chunks

Chunk #	| Size  | Expected MD5                     | Actual MD5
-------	| ----- | ------------                     | ----------
2	| 3	| 7c0c0577834d29be479910502833588a | 7c0c0577834d29be479910502833588a
3	| 2	| bf072e9119077b4e76437a93986787ef | bf072e9119077b4e76437a93986787ef
4	| 5	| 2debfdcf79f03e4a65a667d21ef9de14 | 2debfdcf79f03e4a65a667d21ef9de14

### Test total file

.        | Size	| MD5
-------- | ----	| ---
Expected | 10	| 19af6b658424206d13f90ccd9b49fadf
Actual   | 10	| 95ea0ccd1956d93522bb4e752165dfd1

### Contents of downloaded file
```
IS
A
TEST
```
# Upload chunks are out of order
Chunk 1 payload: `{"number":"5","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`
Chunk 2 payload: `{"number":"6","size":"3","hash":{"value":"7c0c0577834d29be479910502833588a","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-03T19:05:37.774Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-03T19:05:41.428Z",
  "is_consistent": true,
  "purged_on": null,
  "error_on": null,
  "error_message": null
}
```
### Test chunks

Chunk #	| Size  | Expected MD5                     | Actual MD5
-------	| ----- | ------------                     | ----------
3	| 2	| bf072e9119077b4e76437a93986787ef | bf072e9119077b4e76437a93986787ef
4	| 5	| 2debfdcf79f03e4a65a667d21ef9de14 | 2debfdcf79f03e4a65a667d21ef9de14
5	| 5	| 8f99594aa44f8617fa505d20f3d32ec2 | 8f99594aa44f8617fa505d20f3d32ec2
6	| 3	| 7c0c0577834d29be479910502833588a | 7c0c0577834d29be479910502833588a

### Test total file

.        | Size	| MD5
-------- | ----	| ---
Expected | 15	| 19af6b658424206d13f90ccd9b49fadf
Actual   | 15	| 174b77b37661521f471133796eaf3c87

### Contents of downloaded file
```
A
TEST
THIS
IS
```
