# DDS-902 Upload Status

## Deployment View

status: in progress

###### Deployment Requirements

N/A

## Logical View

#### Background

The transition to an eventual consistency model for chunked uploads has exposed a weakness in the state model for uploads. Prior to eventual consistency, when clients completed an upload (i.e. `PUT /uploads/{id}/complete`), it was a synchronous operation - the response signaled completion of the upload (i.e. storage backend chunk manifest had been persisted) and informed clients of any integrity errors. This is now an asynchronous operation (off-loaded to queue worker), and clients need a mechnism to retrospectively determine if the storage processing (i.e. manifest persistence) has been completed and there are no integritey errors.

## Implementation View

The state model will be refactored as follows the for `uploads` resource:

#### Design Option A

+ **status.initiated_on** - When client initiated chunked upload via `POST /projects/{id}/uploads` 
+ **status.completed_on** - When client signaled the chunked upload was complete via `PUT /uploads/{id}/complete` - it has been placed on the queue for worker.
+ **status.verified_on** - The storage subsystem chunk manifest has been created and integrity checks have passed (i.e. all chunks reported exist, chunks size and hashes match what client reported).
+ **status.error_on** - An error was encountered - (i.e could not create manifest or integrity check failed).
+ **status.error_message** - Associated error message. 

*The `verified_on` and and `error_on` properties are mutually exclusive.*

#### Design Option B

+ **initiated** - When client initiated chunked upload via `POST /projects/{id}/uploads`
+ **completed** - The client has signaled that the upload is complete via `PUT /uploads/{id}/complete` - it has been placed on the queue for worker.
+ **verified** - The storage system chunk manifest has been created and integrity checks have passed (i.e. all chunks reported exist, chunks size and hashes match what client reported).
+ **error** - An error was encountered - (i.e could not create manifest or integrity check failed).

The state model will be presented as follows in the `uploads` resource:

```
"status": {
	"current": {
		"state": "verified",
		"state_on": "2017-01-01T13:00:00Z"
	},
	"prior": [
		{
			"state": "completed",
			"state_on": "2017-01-01T12:59:30Z"
		},
		{
			"state": "initiated",
			"state_on": "2017-01-01T12:30:00Z"
		}
	]
}
```

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
