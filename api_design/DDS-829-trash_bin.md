# DDS-829 Trash Bin

## Deployment View

status: proposed

N/A

## Logical View

The trash bin API will allow users to manage deleted objects.  The API allows users to view, restore, and purge (i.e. permanently remove) deleted objects.  Objects that are moved to the "trash bin" when deleted are as follows: **folders, files, and file versions**.

*The deletion of an entire project is a permanent (destructive) operation.  The project and all of its contents are immediately considered "purged" and are not moved to the trash bin, therefore projects cannot be restored.  Client apps should implement delete confirmation workflow, such as requiring users to enter the project name.*

#### API Summary

|Endpoint |Description |
|---|---|
| `GET /trashbin/projects/{id}/children{?name_contains}{?recurse}` | Get a list of immediate descendants of the project that are in the trash bin.  If `recurse=true` is specified, a recursive search is performed. If name_contains is specified, only objects whose name contains the provided value are returned (works with or without recurse mode). The results are sorted in most recently deleted order. |
| `GET /trashbin/folders/{id}/children{?name_contains}{?recurse}` | Get a list of immediate descendants of the folder that are in the trash bin.  If `recurse=true` is specified, a recursive search is performed. If name_contains is specified, only objects whose name contains the provided value are returned (works with or without recurse mode). The results are sorted in most recently deleted order. |
| `GET /trashbin/{object_kind}/{object_id}` | Get instance of object that has been deleted (i.e. moved to trash bin). |
| `PUT /trashbin/{object_kind}/{object_id}/restore` | Restore the specified object and all descendants (recursive) from the trash bin to the specified parent; an exception is thrown if parent does not exist, is deleted, or is purged. |
| `PUT /trashbin/{object_kind}/{object_id}/purge` | Purges the specified object and all descendants (recursive) from the trash bin; once purged, the object is no longer visible from the trash bin context. Any time a data_file is purged, all of its file_versions are purged, which permanently removes their file content from the storage provider (e.g. Duke OIT Swift). |


**Note:** *An object is considered to be in the trash bin if it has been deleted (`"is_deleted": true`), but not purged (`"is_purged": false`); a purged object is immutable.*

#### API Specification
This section defines the proposed API interfaces.

##### List objects in trash bin that are project descendants
`GET /trashbin/projects/{id}/children{?name_contains}{?recurse}`

###### Permissions
authenticated [scope: view_project]

###### Response Messages
* 200: Success
* 401: Unauthorized

##### List objects in trash bin that are folder descendants
`GET /trashbin/folders/{id}/children{?name_contains}{?recurse}`

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
* 404: Object kind not supported
* 404: Object not found in trash bin

##### Restore object from the trash bin
`PUT /trashbin/{object_kind}/{object_id}/restore`

###### Permissions
create\_file or system\_admin

###### Response Messages
* 200: Success
* 404: Parent object does not exist or is itself in the trashbin
* 401: Unauthorized
* 403: Forbidden
* 404: Object or Parent kind not supported
* 404: Object not found in trash bin
* 404: Parent object does not exist or is itself in the trashbin

###### Request Parameters
**parent.kind (string, required unless file_version is being restored for a dds-file that is not in the trashbin)** - The kind of parent object; this can be a project (`dds-project`) or folder (`dds-folder`).  
**parent.id (string, required unless file_version is being restored for a dds-file that is not in the trashbin)** - The unique id of the parent.

###### Rules
+ If a file (`dds-file`) is restored, all deleted version history will be restored as well.
+ If restore of a file version (`dds-file-version`) is requested, the "owning" file must not, itself, be in the trash bin.

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

## Implementation View

+ The audit trail will track restore and purge events for objects.  The sample below shows what this may look like if returned with object payload.  Returning with payload is contingent upon optimizing serialization of audit details and perhaps making them optional for list operations.

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

+ Because this proposed design supports restoring file versions (and associated file upload object) to a different project - we need to refactor the data model.  Currently the `project.id` is used as the container (bucket) ID in the storage subsystem (OIT Swift), and our software resolves the location
of the upload using the project.id and upload.id at request time.  This tightly couples a file upload with a project.  The following refactoring will de-couple this dependency:
	+ Add `container_id` to the `uploads` model/table - this will be assigned the `projects.id` when an upload for a project is initiated - the `uploads.container_id + uploads.id` will be used to locate the indexed object in the storage system (i.e. OIT Swift) - these are immutable attributes.
	+ When a file version is restored to a different project, the `uploads.project_id` will be updated to reference the new project.  
	+ These changes will also allow us to extend the `/move` endpoints to support cross project moves.
  + **IMPORTANT** we will need a data migration upon initial deployment to each heroku environment which sets the container_id to the current project.id for all existing (completed, consistent) uploads.

+ FileVersion will have a manage_upload method that submits a UploadStoragePurgeJob for its upload when
is_purged is set to true (after_save).

###### Background Workers

upload\_storage\_purge_job: worker that monitors a queue for uploads to purge, and destroys their swift storage object.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
