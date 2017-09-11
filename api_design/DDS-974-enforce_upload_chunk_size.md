# DDS-974 Enforce Upload Chunk Size

## Deployment View

N/A

## Logical View

A critical issue was recently exposed with the chunked upload capability.  The  storage provider (Swift), is configured with a set maximum number of segments (i.e. Data Service chunks), beyond which it cannot coalesce a large file.  To remedy this situation, the API will be extended to enforce a minumum chunk size, based on the overall file size and max segments setting.

#### Summary of impacted APIs

|Endpoint |Description |
|---|---|
| `POST /projects/{id}/uploads` | Intitate a chunked upload. |
| `PUT /uploads/{id}/chunks` | Generate and return a pre-signed upload URL for a chunk.  |

#### API Specification
This section defines the proposed API interface extensions.

##### Intitate a chunked upload
`POST /projects/{id}/uploads`

###### Response Headers (Extensions)
The following custom response headers will be added to inform clients of the minimum chunk size that may be utlized to ensure chunks can be coalesced, as well as the maximum chunk size the storage provider can accommodate.

+ **x-min-chunk-upload-size** - The minimum chunk size in bytes.
+ **x-max-chunk-upload-size** - The maximum chunk size in bytes.

##### Generate and return a pre-signed upload URL for a chunk
`PUT /uploads/{id}/chunks`

###### Response Messages (Extensions)
+ 400 - Invalid chunk size specified, must be in range {min}-{max}

###### Response Example 
```
{
	"error": 400,
	"code": "invalid_chunk_size",
	"reason": "Invalid chunk size specified, must be in range {min}-{max}"
	"suggestion": "Use valid chunk size"
}
```
	
## Implementation View

+ The offcial GCB python client and DDS Web portal client will need to be modifed to interface with these chunked upload API extensions.

+ A migration will be needed to remedy any existing uploads that have been marked as completed by the client (i.e. `status.completed_on != null`) and have greater that 1000 chunks (i.e. Swift segments).  This may be accomplished by increasing the `max_manifest_segements` on the Swift instance.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.