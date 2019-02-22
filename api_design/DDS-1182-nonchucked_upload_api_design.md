# DDS-1182 Non-chunked uploads

## Logical View

#### Background

Chunked uploads are useful when dealing with large files. The overhead of the chunked
upload process is not ideal for small files.

#### Proposal

Add a `chunked` boolean attribute to the `POST /projects/{id}/uploads` endpoint.
When `chunked` is false, the returned payload will include a signed url for
uploading data.

For uploads created with a false `chunked` attribute, the payload for the
`GET /uploads/{id}` endpoint will include a signed url for uploading data.

When the client is finished uploading data, the `PUT /uploads/{id}/complete`
endpoint must be called. The hash algorithm may need to be validated to work with
the upload's storage provider. Once the upload has been completed, the payload for
`GET /uploads/{id}` will no longer include a signed url for uploading.

These changes should speed up client interactions by removing the need to call the
`PUT /uploads/{id}/chunks` endpoint to create a signed url for uploading. Also,
since the DDS API does not need to interact with an external service to create
signed urls, latency introduced by the eventual consistency model is also removed.
All changes should be backwards compatible and responses will remain consistent
with the previous version when not utilizing the new functionality.

## Implementation View

#### Summary of impacted APIs

|Endpoint |Description |
|---|---|
| `POST /projects/{id}/uploads` | Initiate upload |
| `GET /uploads/{id}` | View upload |
| `PUT /uploads/{id}/complete` | Complete file upload |
| `PUT /uploads/{id}/chunks` | Get pre-signed chunk URL |

#### API Specification

##### Initiate upload

`POST /projects/{id}/uploads`

###### Request Properties

- *name (string, required)* - The name of the client file to upload.
- *content_type (string, optional)* - Valid content type per [media types](https://en.wikipedia.org/wiki/Internet_media_type).
- *size (number, required)* - The size in bytes of entire file (computed by client).
- *storage_provider.id (string, optional)* - The unique id for a storage provider.
- *chunked (boolean, optional)* - The default is true, returning the established chunked upload payload. When false, chunks are omitted and a signed upload url is returned with the payload.

###### Request Example

```JSON
{
  "name": "RSEM_Normalized_PI3K_RNASeq_Matrix.Rdata",
  "content_type": "application/octet-stream",
  "size": 30024000,
  "storage_provider": {
    "id": "g5579f73-0558-4f96-afc7-9d251e65bv33"
  },
  "chunked": false
}
```

###### Response Example

```JSON
{
  "id": "666be35a-98e0-4c2e-9a17-7bc009f9bb23",
  "project": {"id": "d5ae02a4-b9e6-473d-87c4-66f4c881ae7a"},
  "name": "RSEM_Normalized_PI3K_RNASeq_Matrix.Rdata",
  "content_type": "application/octet-stream",
  "size": 30024000,
  "hashes": [ ],
  "storage_provider": {
    "id": "g5579f73-0558-4f96-afc7-9d251e65bv33",
    "name": "duke_oit_swift", "description":
    "Duke OIT Storage"
  },
  "status": {
    "initiated_on": "2015-07-10T13:00:00Z",
    "completed_on": null,
    "purged_on": null,
    "error_on": null,
    "error_message": null
  },
  "signed_url": {
      "http_verb": "PUT",
      "host": "duke_data_service_prod.s3.amazonaws.com",
      "url": "/666be35a-98e0-4c2e-9a17-7bc009f9bb23?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN...",
      "http_headers": [
        { "Content-Length": "30024000" }
      ]
  },
  "audit": { }
}
```

##### View upload

`GET /uploads/{id}`

###### Rules

###### Response Example

```JSON
{
  "id": "666be35a-98e0-4c2e-9a17-7bc009f9bb23",
  "project": {"id": "d5ae02a4-b9e6-473d-87c4-66f4c881ae7a"},
  "name": "RSEM_Normalized_PI3K_RNASeq_Matrix.Rdata",
  "content_type": "application/octet-stream",
  "size": 30024000,
  "hashes": [ ],
  "storage_provider": {
    "id": "g5579f73-0558-4f96-afc7-9d251e65bv33",
    "name": "duke_oit_swift", "description":
    "Duke OIT Storage"
  },
  "status": {
    "initiated_on": "2015-07-10T13:00:00Z",
    "completed_on": null,
    "purged_on": null,
    "error_on": null,
    "error_message": null
  },
  "signed_url": {
      "http_verb": "PUT",
      "host": "duke_data_service_prod.s3.amazonaws.com",
      "url": "/666be35a-98e0-4c2e-9a17-7bc009f9bb23?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN...",
      "http_headers": [
        { "Content-Length": "30024000" }
      ]
  },
  "audit": { }
}
```

##### Complete file upload

`PUT /uploads/{id}/complete`

###### Rules

When completing a non-chunked upload, the hash.algorithm must work with the
upload's storage provider.

##### Get pre-signed chunk URL

`PUT /uploads/{id}/chunks`

###### Rules

A 404 NotFound error will be returned when a non-chunked upload id is provided.
