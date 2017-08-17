# DDS-919 Modify Permissions and Rules

## Deployment View

status: in progress

###### Deployment Requirements

N/A

## Logical View

#### Background

Several minor changes to permissions and rules will be implemented.  These changes are as follows:

+ Remove contraint that prevents a user from removing self from a project.
+ Remove contraint that requires a user to be the "owner/creator" of a file to update the file - only require "update_file" permission.


## Implementation View

The impacted endpoint are as follows:
	
`DELETE /projects/{project_id}/permissions/{user_id}`

`PUT /files/{id}`
	
## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.

