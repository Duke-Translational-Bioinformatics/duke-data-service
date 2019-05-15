# Introduction

The Duke Data Service (DDS) provides API supports a multipart upload system to allow efficient uploads of large files (up to 5 Terabytes). The upload workflow has multiple stages. This workflow requires clients to:

1. **Create an Upload**
   - `POST /projects/{project_id}/uploads`
   - The client provides the name, size, and content-type of the file they wish to upload.
   - A UUID for the newly created Upload is returned as part of the response payload.
1. **Create each Chunk**
   - `PUT /uploads/{upload_id}/chunks`
   - The client provides the number, size, and MD5 of the chunk. The number for each chunk must reflect the chunk's position within the file, starting with 1.
   - The response payload is the JSON serialized signed temporary url
1. **Upload each Chunk**
   - The client uses the signed url to upload the exact subset of the file data, corresponding with the chunk number and size, to the storage provider.
1. **Complete the Upload**
   - `PUT /uploads/{upload_id}/complete`
   - Once all file chunks have been created and successfully uploaded, the client completes the upload, providing an MD5 for the entire file.
   - The upload's `completed_on` status is populated with a timestamp, but `is_consistent` remains `false` until DDS has processed the upload.
   - When DDS processes the chunked upload, the upload's size, chunk order, and chunk MD5s are all verified against what has been uploaded to the storage provider.
     - If any part of the verification fails, the `error_on` and `error_message` statuses will be populated.
     - Once complete, the `is_consistent` status is set to `true`, whether or not verification has failed.
     - NOTE: The MD5 reported for the entire file is not verified.
1. **Create a File**
   - `POST /files`
   - The client provides a location within the project's folder hierarchy for the upload.
   - This allows DDS users to navigate to the file for downloading.

In the following report, we document a number of scenarios which describe the various ways a client can upload a multipart file, including situations where the uploaded file does not match the actual file the client intended to upload.

# File sizes and MD5s

A test file was developed, and split into chunks, for use in the different scenarios:

Description | Contents | Size | MD5
----------- | -------- | ---- | ---
test\_file.txt | THIS<br />IS<br />A<br />TEST<br /> | 15 | 19af6b658424206d13f90ccd9b49fadf
chunk 1 | THIS<br /> | 5 | 8f99594aa44f8617fa505d20f3d32ec2
chunk 2 | IS<br /> | 3 | 7c0c0577834d29be479910502833588a
chunk 3 | A<br /> | 2 | bf072e9119077b4e76437a93986787ef
chunk 4 | TEST<br /> | 5 | 2debfdcf79f03e4a65a667d21ef9de14

# Scenario: Upload without errors
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
  "initiated_on": "2019-05-08T15:52:23.386Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-08T15:52:32.980Z",
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
# Scenario: Client reports an incorrect MD5 that does not match the actual MD5 of the file being uploaded
Complete Upload payload: `{"hash":{"value":"thisisabadmd5yo","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-08T15:53:00.570Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-08T15:53:10.342Z",
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
# Scenario: Client fails to register a chunk and reports the actual size of the file for the upload
This can happen if the client just skips a chunk, or if the client reports chunk 1 as chunk 2, and then reports chunk 2 as chunk 2, which will overwrite the chunk 2 values reported for chunk 1.
Chunk 1 payload: `{"number":"2","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`
Chunk 2 payload: `{"number":"2","size":"3","hash":{"value":"7c0c0577834d29be479910502833588a","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-08T15:53:30.744Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-08T15:53:41.808Z",
  "is_consistent": true,
  "purged_on": null,
  "error_on": "2019-05-08T15:53:42.117Z",
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
# Scenario: Client fails to register a chunk but reports the size calculated from chunks 2-4 for the upload
Upload create payload: `{"name":"test_file.txt","content_type":"text%2Fplain","size":"10"}`
Chunk 1 payload: `{"number":"2","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`
Chunk 2 payload: `{"number":"2","size":"3","hash":{"value":"7c0c0577834d29be479910502833588a","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-08T15:53:48.986Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-08T15:53:51.815Z",
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
# Scenario: Client registers the chunks in the wrong order
Chunk 1 payload: `{"number":"5","size":"5","hash":{"value":"8f99594aa44f8617fa505d20f3d32ec2","algorithm":"md5"}}`
Chunk 2 payload: `{"number":"6","size":"3","hash":{"value":"7c0c0577834d29be479910502833588a","algorithm":"md5"}}`
Chunk 3 payload: `{"number":"3","size":"2","hash":{"value":"bf072e9119077b4e76437a93986787ef","algorithm":"md5"}}`
Chunk 4 payload: `{"number":"4","size":"5","hash":{"value":"2debfdcf79f03e4a65a667d21ef9de14","algorithm":"md5"}}`
## Results
### Upload status
```
{
  "initiated_on": "2019-05-08T15:53:56.020Z",
  "ready_for_chunks": true,
  "completed_on": "2019-05-08T15:54:10.613Z",
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
