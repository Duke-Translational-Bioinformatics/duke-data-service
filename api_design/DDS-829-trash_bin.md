# DDS-829 Trash Bin 

## Deployment View

status: proposed

N/A

## Logical View

The trash bin API will allow users to manage deleted objects.  The API allows users to view, restore, and purge (i.e. permanently remove) deleted objects.  Objects that are moved to the "trash bin" when deleted are as follows: **folders, files, and file versions**.

*The deletion of an entire project is a permanent (destructive) operation.  The project and all of its contents are immedialately considered "purged" and are not moved to the trash bin, therefore projects cannot be restored.  Client apps should implement delete (purge) confirmation workflow, such as a requiring users to enter the project name.*

#### API Summary

|Endpoint |Description |
|---|---|
| `GET /trashbin{?name_contains}` | Get a list of all objects in the trash bin and optionally filter list by `name_contains`.  The results are sorted in most recently deleted order. |
| `GET /trashbin/projects/{id}/children{?name_contains}` | Get a list of immediate descendants of the project that are in the trash bin.  If `name_contains` is specified, a recursive search is performed.  The results are sorted in most recently deleted order. |
| `GET /trashbin/folders/{id}/children{?name_contains}` | Get a list of immediate descendants of the folder that are in the trash bin.  If `name_contains` is specified, a recursive search is performed.  The results are sorted in most recently deleted order. |
| `GET /trashbin/{object_id}/{object_kind}` | Get instance of object that has been deleted (i.e. moved to trash bin). |
| `PUT /trashbin/{object_kind}/{object_id}/restore` | Restore the specified object and all descendants (recursive) from the trash bin to original parent or a new parent; an exception is thrown if parent does not exist. |
| `PUT /trashbin/{object_kind}/{object_id}/purge` | Purges the specified object and all descendants (recursive) from the trash bin; once purged, the object is no longer visible from the trash bin context, and in the case of a file version, the file content is permanently removed from the storage provider (e.g. Duke OIT Swift). | 
| `GET /current_user/stats` | Get utilization stats for the current user. | 
| `GET /projects/{id}/stats` | Get utilization stats for the project. |


**Note:** *An object is considered to be in the trash bin if it has been deleted (`"is_deleted": true`), but not purged (`"is_purged": false`); a purged object is immutable.*

#### API Specification
This section defines the proposed API interfaces.

##### List objects in the trash bin
`GET /trashbin{?name_contains}`
 
###### Permissions
authenticated [scope: view_project] 

###### Response Messages
* 200: Success
* 401: Unauthorized

##### List objects in trash bin that are project descendants
`GET /trashbin/projects/{id}/children{?name_contains}`
 
###### Permissions
authenticated [scope: view_project] 

###### Response Messages
* 200: Success
* 401: Unauthorized

##### List objects in trash bin that are folder descendants
`GET /trashbin/folders/{id}/children{?name_contains}`
 
###### Permissions
authenticated [scope: view_project] 

###### Response Messages
* 200: Success
* 401: Unauthorized

##### Get an instance of an object that has been deleted (moved to trash bin)
`GET /trashbin/{object_kind}/{object_id}`
 
###### Permissions
view_project 

###### Response Messages
* 200: Success
* 401: Unauthorized
* 403: Forbidden
* 404: Object not found in trash bin

##### Restore object from the trash bin
`PUT /trashbin/{object_kind}/{object_id}/restore`
 
###### Permissions
create\_file or system\_admin

###### Response Messages
* 201: Success
* 400: Parent object does not exist
* 401: Unauthorized
* 403: Forbidden
* 404: Object not found in trash bin

###### Request Parameters
**parent.kind (string, optional)** - The kind of parent object; this can be a project (`dds-project`) or folder (`dds-folder`).  
**parent.id (string, optional)** - The unique id of the parent.

###### Rules
+ If no request payload is provided, an attempt will be made to restore to original parent.  
+ If a file (`dds-file`) is restored, all deleted version history will be restored as well.
+ If restore of a file version (`dds-file-version`) is requested and the "owning" file is in the trash bin, then an entire file restore will be perfomed - including all deleted version history.

###### Request Example
`PUT /trashbin/dds-file-version/777be35a-98e0-4c2e-9a17-7bc009f9b111/restore`  

```
{
  "parent": {
    "kind": "dds-folder",
    "id": "482be8c5-209d-4e3b-afaf-cb66686ffbcc"
  }
}
```

##### Purge object from the trash bin
`PUT /trashbin/{object_kind}/{object_id}/purge`
 
###### Permissions
project\_admin or system\_admin

###### Rules
+ Purge of a specific file version (`dds-file-version`) cannot be performed via this endpoint - version can only be purged via the "owning" file (`dds-file`).

###### Request Example
`PUT /trashbin/dds-file/888be35a-98e0-4c2e-9a17-7bc009f9b222/purge`  

##### Get utilization stats for the current user
`GET /current_user/stats`
 
###### Permissions
authenticated [scope: view_project]

###### Response Example
```
{
   "admin_owner_stats": {
   		"projects_count": 2,
   		"total_bytes": 102046000,
   		"in_trash_bytes": 50240000
   },
   "collaborator_stats": {
   		"projects_count": 20
   }
}
```

##### Get utilization stats for a project
`GET /projects/{id}/stats`
 
###### Permissions
authenticated [scope: view_project]

###### Response Example
```
{
   "stats": {
   		"total_bytes": 102046000,
   		"in_trash_bytes": 50240000
   	}
}
```
		
## Implementation View

+ The audit trail will record restore and purge events for objects.  The sample below shows what this may look like if we returned with object payload.  Returning with payload is contingent upon optimizing serialization of audit details and perhaps making them optional for list operations. 

```
"audit": {
      "created_on": "2015-01-01T12:00:00Z",
      "created_by": {
          "id": "ce245d81-bae1-452b-8589-24f736ca7735",
          .... etc ....
      }
      .... updated and deleted history here .... 
      "restored_on": null,
      "restored_by": null,
      "purged_on": null,
      "purged_by": null
  }
```

+ A new property `is_purged` will be added to the payload for **folder, file, and file version** resources.  

+ In the context of provenance queries, purged objects (i.e. graph nodes) should still be returned.

+ Because this proposed design supports restoring file versions (and associated upload object) to a different project - we need to refactor the data model.  Currently the `project.id` is used as the container (bucket) identifier in the storage system (OIT Swift).  The following refactoring will de-couple this dependency:
	+ Add a `container_id` (UUID) to the `projects` model/table - this will be used as the storage systems container/bucket that houses file uploads (i.e. storage objects) for the project.
	+ Add `container_id` to the `uploads` model/table - this will be assigned to the `projects.container_id` when an upload for a project is initiated - the `uploads.container_id + uploads.id` will be used to locate the indexed object in the storage system (i.e. OIT Swift) - these are immutable attributes. 
	+ Update `uploads.project_id` to reference the new project number when a file version (and associated upload) is restored to the project.  
	+ These changes will also allow us to extend the `/move` endpoints to support cross project moves.

+ Deprecate `GET /current_user/usage` - leverage new endpoints `GET /current_user/stats` and `GET /projects/{id}/stats`

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.