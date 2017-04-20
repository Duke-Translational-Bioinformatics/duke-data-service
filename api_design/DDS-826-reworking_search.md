Background (Existing Search API)
-----

The initial implementation of the DDS search API has exposed several usage issues.  These issues, which stem from the fact that consumers can pass-through native Elactic DSL, are as follows: 

* Elastic DSL is complex and requires a deep-dive by consumers to understand how to construct valid queries and requires knowledge of the underlying indexing (analyzer) strategy used for the Elastic documents.

* Testing of the endpoint is problematic - the query options to consumers are only constrained by the broad scope of Elastic DSL.

* The endpoint is fragile in terms of migrating to new versions of Elastic, modifying index strategies, and modifying indexed document schemas (mappings).

Moving Forward (New Search API)
----

The following is a proposed design to replace the exisiting API, which will no longer allow native Elastic DSL pass-through.  The intent is to design a consumer interface that is simple out of the gate, but can grow with increased demand for search capabilites.

##API Specification

This section defines the proposed API interface.

####URL

`POST /search/folders_files`

####Response Messages
* 201: Success
* 400: Invalid value specified for query_string.fields
* 400: Invalid "{key: value}" specified for filters[].object
* 400: Required fields - facets[].field, facets[].name must be specified 
* 400: Invalid value specified for facets[].field
* 400: Invalid size specified for facets[].size - out of range
* 401: Unauthorized

###Query Parameters

**query_string.query (string, optional)** - The string fragment (phrase) to search for in `query_string.fields`.  If specified, must be at least 3 characters to invoke search operation.

**query_string.fields (string[ ], optional)** - List of text fields to search; valid options are `name` and `tags.label`.  If not specified, defaults to all valid options.

**filters (object[ ], optional)** - List of boolean search objects (predicates) that are joined together by the *AND* operator - they are represented as `key: value` pairs.

**The following filter object `keys` are currently supported:**

**kind** - Limit search context to list of kinds; valid options are `dds-folder` and `dds-file` - requires a set of comma-delimited kinds like so: `{"kind": ["dds-file"]}`. If not specified, defaults to all valid options.
 
**project.id** - Limit search context to list of projects; requires a set of comma-delimited ids like so: `{"project.id": ["345e...", "2e45..."]}`. If not specified, defaults to projects in which the current user has view permission.

**facets (object[ ], optional)** - List of facets (aggregates) that should be computed.

**If specified, each facet object has the following properties:**

**facets[ ].field (string, required)** - The field for which you want to compute facet; valid options are `project.name` and `tags.label`.

**facets[ ].name (string, required)** - The name to give the group of computed facet buckets for the field; for example: `project_names` and `tags`	.

**facets[ ].size (number, optional)** - The number of facet buckets to return with the results; defaults to the top 20 and cannot be greater than 50.


API Usage Example
----

This section provides a walk-through of the API for a concrete use case.  The examples herein were run against the DDS production Bonsai interactive console.  The Elastic search endpoint is: `POST /data_files/_search?pretty`.

###The Query Request

`POST /search/folders_files`

```
{
  "query_string": {
    "query": "digital coll"
  }
  "filters": [
    {"kinds": ["dds-file"]},
    {"project_ids": ["319e7e82-037b-4e64-af6f-5620b45e7b06", "2cdafa6b-66ce-491c-8c58-bb6430a3e969", "fea9a9f9-3428-4ee5-8a55-d5b43c19d0fa"]}
  ],
  },
  "facets": [
     {"field": "project.name", "name": "project_names", "size": 20},
     {"field": "tags.label", "name": "tags", "size": 20},
  ]
}
```

###The Query Request transform to Elastic DSL

When the above query request is submitted to the DDS search endpoint, the request payload is transformed into the following Elastic DSL: 

```
{
  "_source": ["name", "project", "tags"],
  "query": { 
     "filtered": {
        "query": {
           "query_string": {
              "fields": ["name", "tags.label"],
              "query": "*digital coll* *digital* *coll*"
           }
         },
         "filter": {
            "bool" : {
               "must" : [
                 {"terms": {"kind": ["dds-file"]}},
                 {"terms": {"project.id": ["319e7e82-037b-4e64-af6f-5620b45e7b06", "2cdafa6b-66ce-491c-8c58-bb6430a3e969", "fea9a9f9-3428-4ee5-8a55-d5b43c19d0fa" ]}}
               ]
            }
         }
     }
  },
  "aggs": {
     "project_names": {
        "terms": {
            "field": "project.name",
            "size": 20
         }
     },
     "tags": {
        "terms": {
           "field": "tags.label.raw",
           "size": 20
         }
     }
  }
}
```









