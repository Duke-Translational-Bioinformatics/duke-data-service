# DDS-872 Eventual Consistency Status

## Deployment View

status: proposed

###### Deployment Requirements

N/A

## Logical View

#### Background 

The DDS API will transition to an eventual consistencey model, due to the distributed nature of the data systems supporting the API. This means that the result of an API command that modifies a resource may not be immediately visible to all subsequent API commands. 

#### Clients and Eventual Consistency

The following is a set of proposed changes and extensions to the exisiting API that will help inform clients of the state of their API resources from an eventual consistency perspective.

###### Endpoint URL `GET /projects/{id}?{info}`

###### New Query Parameters
**info** - If specified, returns extended information about the project, including eventual consistency details.

###### New Response Properties
**info.resource\_consistency.is_upload\_ready** - Specifies that the project can accept file uploads.

**info.resource\_consistency.is_download\_ready** - Specifies that all files contained in the project can be downloaded. (this excludes *deleted* files)

###### Response Example
```
{
	...standard project resource...
	"info": {
		"resource_consistency": {
			"is_upload_ready": true,
			"is_download_ready": true
		}
	}
}			
``` 
###### Endpoint URL `GET /files/{id}/url?{info}`

###### New Query Parameters
**info** - If specified, returns extended information about the file, including eventual consistency details.

###### New Response Properties
**info.resource\_consistency.is_download\_ready** - Specifies that the file can be downloaded.

###### Response Example
```
{
	...standard project resource...
	"info": {
		"resource_consistency": {
			"is_upload_ready": true,
			"is_download_ready": true
		}
	}
}			
``` 

###### Endpoint URL `POST /projects/{id}/uploads`

###### New Response Messages
* 404: Resource not consistent

Example `404: Resource not consistent` payload

```
{ 
	"error": 404,
	"code": "resource_not_consistent",
	"reason": "resource changes are still being processed by system"
	"suggestion": "this is a temporary state that will eventually be resolved by the system; please retry request"
}
```

 
## Implementation View

N/A

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.