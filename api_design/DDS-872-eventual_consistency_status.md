# DDS-872 Eventual Consistency Status

## Deployment View

status: proposed

###### Deployment Requirements

N/A

## Logical View

#### Background

The DDS API will transition to an eventual consistencey model, due to the distributed nature of the data systems supporting the API. This means that the result of an API command that modifies a resource may not be immediately visible to all subsequent API commands.

#### Clients and Eventual Consistency

Endpoints impacted by eventual consistency will be extended to include a response that will inform clients when resources are not consistent.  This will allow developers to build intelligent retry logic into their client applications.

###### Extended Endpoint URLs
 `POST /projects/{id}/uploads`

 `GET /files/{id}/url`

 `GET /file_versions/{id)/url`

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
  "reason": "reported chunk hash/size does not match that computed by StorageProvider",
  "suggestion": "You must begin a new upload process"
}
```

## Implementation View

This design introduces a `code` property into the standadard DDS error response that allows clients to differentiate responses that have the same HTTP response status code/number.

For responses in which a code is not relevant or has not been implemented yet, the following will be returned for the `code` property:`"code": "not_provided"`.

We need to remove the following potential exception from the apidocs/swagger for PUST /uploads
[400, 'IntegrityException: reported file size or chunk hashes do not match that computed by StorageProvider'],
[500, 'Unexpected StorageProviderException experienced']

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
