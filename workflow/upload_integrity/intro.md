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
     - NOTE: The MD5 reported for the overall upload is not verified.
1. **Create a File**
   - `POST /files`
   - The client provides a location within the project's folder hierarchy for the upload.
   - This allows DDS users to navigate to the file for downloading.

It is possible for a client to create a file in the DDS that does not match the original file, but which does not report an inconsistency error, and can be downloaded by the download urls. This would not be discovered until a user downloads the complete file, and compares the MD5, and the size, of the actual file downloaded against the values reported by the upload client.

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

