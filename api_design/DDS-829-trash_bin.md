# DDS-829 Trash Bin 

## Deployment View

status: proposed

N/A

## Logical View

The trash bin API will allow users to manage deleted objects.  The API allows users to view, restore, and purge (i.e. permanently remove) deleted objects.  Objects that are moved to the trash bin when deleted are as follows: projects, folders, files, and file versions.

###### API Summary

|Endpoint |Description |
|---|---|
| `GET /projects/trashbin` | Get a listing of projects in the trash bin. |
| `GET /projects/{id}/trashbin{?name_contains}` | Get a recursive listing of objects in the trash bin that are descendants of the specified project. |
| `GET /folders/{id}/trashbin{?name_contains}` | Get a recursive listing of objects in the trash bin that are descendants of the specified folder. |
| `PUT /trashbin/{object_kind}/{object_id}/restore` | Restore the specified object and all descendants (recursive) from the trash bin to original parent or a new parent; an exception is thrown if parent does not exist. |
| `PUT /trashbin/{object_kind}/{object_id}/purge` | Purges the specified object and all descendants (recursive) from the trash bin; once purging is done, the object is no longer visible from the trash bin context, and in the case of a file version, the file content is permanently removed from the storage provider (i.e. Duke OIT Swift). | 

**Note:** *An object is considered to be in the trash bin if it has been deleted (`"is_deleted": true`), but not purged (`"is_purged": false`); a purged object is immutable.*

##### API Specification
This section defines the proposed API interfaces.

###### Endpoint URL - List projects in trash bin
`GET /projects/trashbin` 
 
###### Endpoint permissions
authenticated [scope: view_project] 

###### Response Messages
* 200: Success
* 401: Unauthorized

###### Response 
This will return a collection of project resources in trash bin.

###### Endpoint URL - List objects in trash bin that are project descendants
`GET /projects/{id}/trashbin{?name_contains}`
 
###### Endpoint permissions
authenticated [scope: view_project] 

###### Response Messages
* 200: Success
* 401: Unauthorized

###### Response 
This will return a collection of descendant resources for the project; this includes: folders, files, and file versions.

###### Endpoint URL - List objects in trash bin that are folder descendants
`GET /folders/{id}/trashbin{?name_contains}`
 
###### Endpoint permissions
authenticated [scope: view_project] 

###### Response Messages
* 200: Success
* 401: Unauthorized

###### Response 
This will return a collection of descendant resources for the folder; this includes: folders, files, and file versions.

###### Endpoint URL - Restore object from the trash bin
`PUT /trashbin/{object_kind}/{object_id}/restore`
 
###### Endpoint permissions
create\_file for project context of parent object OR  
system_admin

###### Response Messages
* 201: Success
* 400: parent project/folder does not exist
* 401: Unauthorized
* 403: Forbidden

###### Request Parameters
**parent.kind (string, optional)** - The kind of parent container; this can be a project (`dds-project`) or folder (`dds-folder`).  
**parent.id (string, optional)** - The unique id of the parent.

###### Rules
+ If restore of a project (`dds-project`) is requested, any provided request payload is ignored.
+ If the no request payload is provided, an attempt will be made to restore to the objects original parent.  
+ If restore of a file version (`dds-file-version`) is requested, the owning file will be restored as well if it is in the trash bin.  

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

###### Response
None

###### Endpoint URL - Purge object from the trash bin
`PUT /trashbin/{object_kind}/{object_id}/purge`
 
###### Endpoint permissions
project\_admin OR system\_admin

###### Request Example
`PUT /trashbin/dds-file-version/777be35a-98e0-4c2e-9a17-7bc009f9b111/purge`  

###### Response
None

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

+ A new property `is_purged` will be added to the payload for project, folder, file, and file version resources.  

+ Should purged objects still be visible in the context of provenance?

+ Consider adding an endpoint that allows clients to get storage stats for a project or a folder (i.e. `GET /projects/{id}/stats`) - this would return something liken to:  

```
{
   "storage": {
     "folder_count": 20,
     "file_count": 1000,
     "total_storage_bytes": 102046000,
     "trashbin_storage_bytes": 50240000
   }
}
```
This would give project owners insight to projects storage utilization.  Perhaps we should deprecate `GET /current_user/useage` - not sure value of this and if it is clear to user what it implies when this information is viewed via the Web portal.  Seems like project level view is more relevant - especially for project in which I am the owner.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.