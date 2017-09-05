# DDS-902 Upload Status

## Deployment View

status: in progress

###### Deployment Requirements

N/A

## Logical View

#### Background

The transition to an eventual consistency model for chunked uploads has exposed a weakness in the state model for uploads. Prior to eventual consistency, when clients completed an upload (i.e. `PUT /uploads/{id}/complete`), it was a synchronous operation - the response signaled completion of the upload (i.e. storage backend chunk manifest had been persisted) and informed clients of any integrity errors. This is now an asynchronous operation - off-loaded to a queue worker, and clients need a mechanism to retrospectively determine if the storage processing (i.e. manifest persistence and integrity checks) completed successfully.

## Implementation View

A new status property `status.verified_on` will be added the the `upload.status` resource.  For completeness, the defintion of this new status property, as well as the exisiting status properties follows: 

+ **status.initiated_on** - When client initiated chunked upload via `POST /projects/{id}/uploads` 
+ **status.completed_on** - When client signaled the chunked upload was complete via `PUT /uploads/{id}/complete` - the upload is placed on the queue for a worker to generate manifest and verify integrity.
+ **status.verified_on** - The storage subsystem manifest has been created and integrity checks have passed (i.e. all chunks reported exist, chunks size and hashes match what client reported).
+ **status.error_on** - An error was encountered - (i.e could not create manifest or integrity check failed).
+ **status.error_message** - Associated error message. 

**The `status.verified_on` and `status.error_on` properties are mutually exclusive.**

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
