
# DDS-881 Extending Metadata to Provenance Activities 

## Deployment View

status: proposed

N/A

## Logical View

The first iteration of the Metadata API (tags and key/value pairs) only allowed for the annotation of data files (i.e. `dds-file`).  The API implementation will be extended to support the annotation of provenance activities as well.  The API URL(s) do not need to change, but the permissions model needs to be extended to support provenance activities.

##### Updated permissions model for Tags endpoints

###### Endpoints
`POST /tags/{object_kind}/{object_id}`  
`POST /tags/{object_kind}/{object_id}/append`  
`DELETE /tags/{id}`

*Permissions:* update_file when object is file OR  
creator when object is activity 

###### Endpoints (List operations)
`GET /tags/{object_kind}/{object_id}`  
`GET /tags/labels{?object_kind,label_contains}`

*Permissions:* authenticated  
[scope: view_project when object is file] OR  
[scope: creator when object is activity] OR  
[scope: visiblity to single entity that has a provenance relation when object is activity]

###### Endpoints
`GET /tags/{id}`

*Permissions:* view_project when object is file OR  
creator when object is activity OR  
visiblity to single entity that has a provenance relation when object is activity

##### Updated permissions model for Metadata (key/value pairs) endpoints

###### Endpoints
`POST /meta/{object_kind}/{object_id}/{template_id}`
`PUT /meta/{object_kind}/{object_id}/{template_id}`
`DELETE /meta/{object_kind}/{object_id}/{template_id}`

*Permissions:* update_file when object is file OR  
creator when object is activity 

###### Endpoints (List operations)
`GET /meta/{object_kind}/{object_id}`

*Permissions:* authenticated  
[scope: view_project when object is file] OR  
[scope: creator when object is activity] OR  
[scope: visiblity to single entity that has a provenance relation when object is activity]

###### Endpoints
`GET /meta/{object_kind}/{object_id}/{template_id}`

*Permissions:* view_project when object is file OR  
creator when object is activity OR  
visiblity to single entity that has a provenance relation when object is activity

## Implementation View
The permissions model for annotations (tags and key/value pairs) are inherited from the owning objects permissions.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.