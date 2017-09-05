# DDS-930 User/Project Stats

## Deployment View

status: proposed

N/A

## Logical View

The design of the trash bin APIs exposed a need for users to have insight to their utilization stats.

#### API Summary

|Endpoint |Description |
|---|---|
| `GET /project/stats` | List project level stats for user - user must have visibility to the listed projects. |
| `GET /projects/{id}/stats` | Get stats for a specific project - user must have visibility to project. |
| `GET /current_user/stats` | Get stats for the current user across projects - only projects user has visiblity to are included. |

#### API Specification
This section defines the proposed API interfaces.

##### List project level stats
`GET /projects/stats`

###### Permissions
authenticated [scope: view_project]

###### Response Messages
* 200: Success
* 401: Unauthorized

###### Response Example
```
{
  "results": [
	  {
	    "project": {
	    	"id": "482be8c5-209d-4e3b-afaf-cb66686ffbcc",
	    	"name": "Big mouse sequencing"
	    },
	    "current_user_auth_role": {
	        "id": "project_admin",
	        "name": "Project Admin"
	    },
	    "stats": {
		    "active_file_versions": 130,
		    "active_bytes": 1024000,
		    "trash_file_versions": 46,
		    "trash_bytes": 54000,
		    "by_storage_provider": [
		    	{
		    		"id": "e71e2106-2243-4795-a9a0-70de89f68d64",
      				"name": "duke_oit_swift",
      				"description": "Duke OIT Swift Service",
      				"active_file_versions": 130,
		    		"active_bytes": 1024000,
		    		"trash_file_versions": 46,
		    		"trash_bytes": 54000
      			},
      			{...}
		    ]
	    }	    		
     },
     { ... }
  ] 
}
```

##### Get stats for a specific project
`GET /projects/{id}/stats`

###### Permissions
view_project

###### Response Messages
* 200: Success
* 401: Unauthorized
* 403: Forbidden
* 404: Not Found

##### Get stats for the current user across projects
`GET /current_user/stats`

###### Permissions
authenticated [scope: view_project]

###### Response Messages
* 200: Success
* 401: Unauthorized

###### Response Example
**WORK IN PROGRESS**

## Implementation View

+ We need to consider perfomance when computing these stats on demand; perhaps we off-load to queue worker and persist stats when a file event (upload, delete, etc.) occurs for a project.

+ Deprecate `GET /current_user/usage` - leverage new endpoints herein.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.