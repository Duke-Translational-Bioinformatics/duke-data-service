# DDS-1061 Optimized Directory Structure Endpoint

## Deployment View

status: submitted for review

###### Deployment Requirements

## Logical View

The goal of this development epic is to produce a set of endpoints to be used in place of the `/projects/:id/children` and `/folders/:id/children` endpoints.

#### Background

The legacy children endpoints have proven to be suboptimal for the GCB clients needs. The GCB client needs a paginated endpoint to list ALL children of a project or folder. The current children endpoints meet the information needs for their use, but it currently takes on average 15 minutes to get the directory structure for a project or folder with many subfolders and files (similar to our ua_test sprawl project).

#### Design

We will start with the following exemplar of the response provided by the current children endpoint. The goal of this phase is to tease out the specific information in this response, and craft a new JSON structure with these specific pieces of information only.

```JSON
{
  "results": [
    {
      "kind": "dds-file",
      "id": "4b24c20b-a4ed-4910-b51a-b747c76c4518",
      "parent": {
        "kind": "dds-project",
        "id": "dd3673ff-b011-4fe4-b843-5470c26938e1"
      },
      "name": "here.pyc",
      "audit": {
        "created_on": "2017-12-19T21:34:46.483Z",
        "created_by": {
          "id": "0fed56c1-98a8-4626-ad05-4193979d70b2",
          "username": "dcl9",
          "full_name": "Dan Leehr",
          "agent": {
            "id": "2f64f658-f2bf-488c-b3a5-fec01dd4f07b",
            "name": "DukeDSClient"
          }
        },
        "last_updated_on": null,
        "last_updated_by": null,
        "deleted_on": null,
        "deleted_by": null
      },
      "is_deleted": false,
      "current_version": {
        "id": "3217897d-8668-4012-9c11-59d1ad38356e",
        "version": 1,
        "label": null,
        "upload": {
          "id": "39b3dbb3-d75e-40a1-b47a-0d7bbd3f2afa",
          "size": 5843,
          "storage_provider": {
            "id": "306c3607-b1bf-43bf-be7a-1025adcab255",
            "name": "OIT Swift",
            "description": "Duke OIT Swift Service"
          },
          "hashes": [
            {
              "algorithm": "md5",
              "value": "866aecf23d71d084133007b6122f1be5",
              "audit": {
                "created_on": "2017-12-19T21:34:46.345Z",
                "created_by": {
                  "id": "0fed56c1-98a8-4626-ad05-4193979d70b2",
                  "username": "dcl9",
                  "full_name": "Dan Leehr",
                  "agent": {
                    "id": "2f64f658-f2bf-488c-b3a5-fec01dd4f07b",
                    "name": "DukeDSClient"
                  }
                },
                "last_updated_on": null,
                "last_updated_by": null,
                "deleted_on": null,
                "deleted_by": null
              }
            }
          ]
        }
      },
      "project": {
        "id": "dd3673ff-b011-4fe4-b843-5470c26938e1",
        "name": "pythonint_test"
      },
      "ancestors": [
        {
          "kind": "dds-project",
          "id": "dd3673ff-b011-4fe4-b843-5470c26938e1",
          "name": "pythonint_test"
        }
      ]
    },
    {
      "kind": "dds-folder",
      "id": "e6849ace-be52-4284-9112-055a85fcbc00",
      "parent": {
        "kind": "dds-project",
        "id": "dd3673ff-b011-4fe4-b843-5470c26938e1"
      },
      "name": "ddsc",
      "is_deleted": false,
      "audit": {
        "created_on": "2017-12-06T17:17:48.940Z",
        "created_by": {
          "id": "b175b4e9-9987-47eb-bb4e-19f0203efbf6",
          "username": "jpb67",
          "full_name": "John Bradley",
          "agent": {
            "id": "6646b1b6-c8c2-44fe-8882-85be930bde17",
            "name": "DukeDSClient"
          }
        },
        "last_updated_on": null,
        "last_updated_by": null,
        "deleted_on": null,
        "deleted_by": null
      },
      "project": {
        "id": "dd3673ff-b011-4fe4-b843-5470c26938e1",
        "name": "pythonint_test"
      },
      "ancestors": [
        {
          "kind": "dds-project",
          "id": "dd3673ff-b011-4fe4-b843-5470c26938e1",
          "name": "pythonint_test"
        }
      ]
    }
  ]
}
```

## Implementation View

#### Summary of impacted APIs

#### API Specification

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
