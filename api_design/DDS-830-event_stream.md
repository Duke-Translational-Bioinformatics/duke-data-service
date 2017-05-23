
# DDS-830 Event Stream 

## Deployment View

status: proposed

N/A

## Logical View

The event stream API will provide insight to actions peformed by users and software agents in the DDS system.  The API will return a list of event objects which will include the details (i.e. "what changed", "who did it", "when it happened") of each event - this will allow client apps to inform end users about these events.

###### Reported Events

Events in DDS either happen within the context of a project or at a system level.  For this initial implementation, only project level events will be reported.  The list of reported events is as follows:

|Event |Kind |Source Object (i.e. changed object) |
|---|---|---|
|Project Created |dds-project-created  |dds-project |
|Project Updated |dds-project-updated  |dds-project | 
|Project Deleted |dds-project-deleted  |dds-project |
|Project Member Added | dds-project-permission-created |dds-project-permission **(\*\*1)** |
|Project Member Removed | dds-project-permission-deleted|dds-project-permission |
|Folder Created | dds-folder-created |dds-folder |
|Folder Renamed | dds-folder-renamed |dds-folder |
|Folder Deleted | dds-folder-deleted |dds-folder |
|Folder Moved | dds-folder-moved |dds-folder |
|File Uploaded | dds-file-uploaded |dds-file-version |
|File Renamed | dds-file-renamed |dds-file |
|File Deleted | dds-file-deleted |dds-file-version |
|File Moved | dds-file-moved |dds-file |
|File Downloaded | dds-file-downloaded **(\*\*2)** |dds-file-version |

**(\*\*1)** Current design does not return a `kind` in the *Project Member Permissions* response payload - we should include for client consistency.

**(\*\*2)** Current design does not track file downloads in audit trail - we should extend to include this event in audit trail; the best we can do here is track that client requested file download URL - actual download is direct communication betweeen client and storage backend (i.e. Swift).

##### API Specification
This section defines the proposed API interface.

###### Endpoint URL
`POST /search/events`

###### Endpoint permissions
authenticated [scope: view_project] 

*The user can only view events in which they have `view_project` permissions for the `source_object` of the event.*

###### Response Messages
* 201: Success
* 401: Unauthorized

###### Query Parameters
**days_limit (integer, required)** - Limit the number of days of event history to include in results - this is relative to the current date.

**kinds (string[ ], optional)** - Only include the specified kinds; reference `Reported Events` for list of valid kinds.

###### Response Properties

A list of event objects with the following structure will be returned: 

**id (uuid)** - The id of the published event. **(\*\*1)**

**kind (string)** - Defines the kind or type of event; reference `Reported Events` for list of valid kinds.

**created_on (datetime)** - The datetime when the event was generated.

**created_by (object)** - The entity that generated the event - a user object with the included software agent if relevant.

**source_object (object)** - The primary object of the event; for example this may be a `dds-folder` or a `dds-file`.

**(\*\*1)** For UUID we will use the audit trail UUID that this event object is derived from.

##### API Usage Example

##### Request

```
{
	days_limit: 3
}
```

##### Response

Results will be sorted by `created_on` in descending order.

```
{
	"results": [
		{
			"id": "80f2b718-a039-4d9d-95ab-4e29453e0d62",
			"kind": "dds-file-uploaded",
			"created_on": "2017-05-23T12:45:00Z"
	      	"created_by": {
	      		"id": "ce245d81-bae1-452b-8589-24f736ca7735",
	      		"username": "mrgardner01",
	      		"full_name": "Matthew Gardner",
	      		"software_agent": {
	      			"id": "9a4c28a2-ec18-40ed-b75c-3bf5b309715f",
	      			"name": "GCB command line tool"
	      		}
	       }, 
	       "object": {
				"kind": "dds-file-version",
	  			"id": "89ef1e77-1a0b-40a8-aaca-260d13987f2b",
	  			"file": {
	  				"id": "777be35a-98e0-4c2e-9a17-7bc009f9b111",
	  				"name": "RSEM_Normalized_PI3K_RNASeq_Matrix.Rdata",
	  			..... remaining file version payload ....
	  		}
	  	},
	  	.....
  	]
}       
```

## Implementation View
N/A

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
