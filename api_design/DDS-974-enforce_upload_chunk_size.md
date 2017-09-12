# DDS-974 Enforce Upload Chunk Size

## Deployment View

The following ENV must be set in all heroku applications:
  - heroku config:set SWIFT_CHUNK_MAX_NUMBER=1000
  - heroku config:set SWIFT_CHUNK_MAX_SIZE_BYTES=5368709122

This must be done before the circle build, in order for rake db:data:migrate
to work.

## Logical View

A critical issue was recently exposed with the chunked upload capability.  The  storage provider (Swift), is configured with a set maximum number of segments (i.e. Data Service chunks), beyond which it cannot coalesce a large file.  To remedy this situation, the API will be extended to enforce a minumum chunk size, based on the overall file size and max segments setting.

#### Summary of impacted APIs

|Endpoint |Description |
|---|---|
| `GET /storage_providers` | List supported storage providers. |
| `GET /storage_providers/{id}` | Get a storage provider. |
| `POST /projects/{id}/uploads` | Inititate a chunked upload. |
| `PUT /uploads/{id}/chunks` | Generate and return a pre-signed upload URL for a chunk.  |

#### API Specification
This section defines the proposed API interface extensions.

##### List supported storage providers / Get a storage provider
`GET /storage_providers` / `GET /storage_providers/{id}`

###### Response Example (Extensions)
The following properties will be added to the storage providers resource:

+ **chunk\_max\_size\_bytes** - The maximum size of a chunk that can be upload.
+ **chunk\_max\_number** - The maximum number of chunks that can be uploaded for a single file.
+ **file\_max\_size\_bytes** - Maximum supported file size that can be uploaded. (`chunk_max_size_bytes * chunk_max_number`)

```
{
      "id": "g5579f73-0558-4f96-afc7-9d251e65bv33",
      "name": "duke_oit_swift",
      "description": "Duke OIT Storage",
      "chunk_hash_algorithm": "md5",
      "chunk_max_size_bytes": 5368709120,
      "chunk_max_number": 1000,
      "file_max_size_bytes": 5497558138880,    
      "is_deprecated": false
}
```

##### Intitate a chunked upload
`POST /projects/{id}/uploads`

###### Response Headers (Extensions)
The following custom response headers will be added to inform clients of the minimum chunk size that may be utlized to ensure chunks can be coalesced, as well as the maximum chunk size the storage provider can accommodate.

+ **x-min-chunk-upload-size** - The minimum chunk size in bytes.
+ **x-max-chunk-upload-size** - The maximum chunk size in bytes.

##### Generate and return a pre-signed upload URL for a chunk
`PUT /uploads/{id}/chunks`

###### Response Messages (Extensions)
+ 400 - Invalid chunk size specified - must be in range {min}-{max}
+ 400 - File size is currently not supported - maximum size is {max_segments * max_chunk_upload_size}

###### Response Example
```
{
	"error": 400,
	"code": "invalid_chunk_size",
	"reason": "Invalid chunk size specified - must be in range {min}-{max}",
	"suggestion": "Use valid chunk size"
}
```

```
{
	"error": 400,
	"code": "invalid_file_size",
	"reason": "File size is currently not supported - maximum size is {max_segments * max_chunk_upload_size}",
	"suggestion": ""
}
```

## Implementation View

+ The offcial GCB python client and DDS Web portal client will need to be modifed to interface with these chunked upload API extensions.

+ The Swift `max_manifest_segements` will be set to 2000 and all uploads that are inconsistent due to exceeding the prior setting of 1000, will be re-queued for processing.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
