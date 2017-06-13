# DDS-872 Eventual Consistency Status

## Deployment View

status: in progress

###### Deployment Requirements

N/A

## Logical View

#### Background

The DDS API will transition to an eventual consistency model, due to the distributed nature of the data systems supporting the API. This means that the result of an API command that modifies a resource may not be immediately visible to all subsequent API commands, and some actions may not be possible until an object has achieved consistency.

#### Clients and Eventual Consistency

Endpoints impacted by eventual consistency will be extended to include a response that will inform clients when resources are not consistent.  This will allow developers to build intelligent retry logic into their client applications.

###### Extended Endpoint URLs
 `POST /projects/{id}/uploads`

 `GET /files/{id}/url`

 `GET /file_versions/{id)/url`

In addition, requests to complete uploads for files and file_versions will no longer
immediately return a Resource Integrity Exception when the reported chunk hash/size does
not match that computed by the external StorageProvider. This status for an upload will
now be made eventually consistent, such that the exception can now only occur on attempts
to access the url endpoints above for a resource that is consistent and has a reported
integrity exception.

###### New Response Messages
* 404: Resource not consistent

###### Example `404: Resource not consistent` payload:

```
{
	"error": 404,
	"code": "resource_not_consistent",
	"reason": "resource changes are still being processed by system"
	"suggestion": "this is a temporary state that will eventually be resolved by the system; please retry request"
}
```

* 400: Resource Integrity Exception

###### Example `400: Resource Integrity Exception` payload:

```
{
  "error": 400,
  "code": "not_provided",
  "reason": "reported chunk hash/size does not match that computed by StorageProvider",
  "suggestion": "You must begin a new upload process"
}
```

## Implementation View

This design introduces a `code` property into the standard DDS error response that allows clients to differentiate responses that have the same HTTP response status code/number.

For responses in which a code is not relevant or has not been implemented yet, the following will be returned for the `code` property:`"code": "not_provided"`.

We need to remove the following potential exception from the apidocs/swagger for `PUT /uploads/:id/complete`
[400, 'IntegrityException: reported file size or chunk hashes do not match that computed by StorageProvider'],
[500, 'Unexpected StorageProviderException experienced']

We will change the success response to [`202: Accepted`](https://httpstatuses.com/202) for the following endpoints:
`PUT /uploads/:id/complete`
`POST /projects`

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
