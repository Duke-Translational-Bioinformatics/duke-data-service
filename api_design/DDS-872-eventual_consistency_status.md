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
 
## Implementation View

This design introduces a `code` property into the standadard DDS error response that allows clients to differentiate responses that have the same HTTP response status code/number.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.