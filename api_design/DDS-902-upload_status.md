# DDS-902 Upload Status

## Deployment View

status: in progress

###### Deployment Requirements

N/A

## Logical View

#### Background

The transition to an eventual consistency model for chunked uploads has exposed a weakness in the state model for uploads. Prior to eventual consistency, when clients completed an upload (i.e. `PUT /uploads/{id}/complete`), it was a synchronous operation - the response signaled completion of the upload (i.e. storage backend chunk manifest had been persisted) and informed clients of any integrity errors. This is now an asynchronous operation (off-loaded to queue worker), and clients need a mechnism to retrospectively determine if the storage processing (i.e. manifest persistence) has been completed and there are no integritey errors.

## Implementation View

The following state model will be implemented for the `uploads` resource:

+ **upload** - The client has initiated and upload via `POST /projects/{id}/uploads` 
+ **verify** - The client has signaled that the upload is complete via `PUT /uploads/{id}/complete` - it has been placed on the queue for worker.
+ **success** - The storage system chunk manifest has been created and integrity checks have passed (i.e. all chunks reported exist, chunks size and hashes match what client reported).
+ **error** - An error has been encountered and cannot be resolved.

The state model will be presented as follows in the `uploads` resource:

```
"status": {
	"current": {
		"state": "success",
		"state_on": "2017-01-01T13:00:00Z"
	},
	"prior": [
		{
			"state": "verify",
			"state_on": "2017-01-01T12:59:30Z"
		},
		{
			"state": "upload",
			"state_on": "2017-01-01T12:30:00Z"
		}
	]
}
```

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
