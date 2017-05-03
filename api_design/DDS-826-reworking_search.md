# DDS-826 Proposed Redesign of Search Interface

## Deployment View

status: proposed

###### Deployment Requirements

We must drop and rebuild the elasticsearch indices for each environment
immediately after we deploy to that environment (possibly as part of the circle build).

## Logical View

#### Background (Existing Search API)

The initial implementation of the DDS search API has exposed several usage issues.  These issues, which stem from the fact that consumers can pass-through native Elactic DSL, are as follows:

* Elastic DSL is complex and requires a deep-dive by consumers to understand how to construct valid queries.  In addtion, knowledge of the underlying indexing (analyzer) strategy used for the Elastic documents is essential.

* Test coverage of the endpoint is problematic - the query options to consumers are only constrained by the broad scope of Elastic DSL.

* The endpoint is fragile when upgrading Elastic version, modifying index strategies, and modifying document schemas (mappings).

#### Moving Forward (New Search API)

The following is a proposed design to replace the exisiting API, which will no longer allow native Elastic DSL pass-through.  The intent is to design a consumer interface that is simple out of the gate, but can grow with increased demand for search capabilites.

##### API Specification
This section defines the proposed API interface.

###### Endpoint URL
`POST /search/folders_files`

###### Response Messages
* 201: Success
* 400: Invalid value specified for query_string.fields
* 400: Invalid "{key: value}" specified for filters[].object
* 400: Required fields - facets[].field, facets[].name must be specified
* 400: Invalid value specified for facets[].field
* 400: Invalid size specified for facets[].size - out of range
* 400: Invalid "{key: value}" specified for post_filters[].object
* 401: Unauthorized

###### Query Parameters
**query_string.query (string, optional)** - The string fragment (phrase) to search for in `query_string.fields`.  If specified, must be at least 3 characters to invoke search operation.

**query_string.fields (string[ ], optional)** - List of text fields to search; valid options are `name` and `tags.label`.  If not specified, defaults to all options.

**filters (object[ ], optional)** - List of boolean search objects (predicates) that are joined together by *AND* operator - they are represented as `key: value` pairs.

***The following filter objects are currently supported:***

**kind** - Limit search context to list of kinds; valid options are `dds-folder` and `dds-file` - requires a set of comma-delimited kinds like so: `{"kind": ["dds-file"]}`. If not specified, defaults to all options.

**project.id** - Limit search context to list of projects; requires a set of comma-delimited ids like so: `{"project.id": ["345e...", "2e45..."]}`. If not specified, defaults to projects in which the current user has view permission.

**facets (object[ ], optional)** - List of facets (aggregates) that should be computed.

***If specified, each facet object has the following properties:***

**facets[ ].field (string, required)** - The field for which you want to compute facet; valid options are `project.name` and `tags.label`.

**facets[ ].name (string, required)** - The name to give the group of computed facet buckets for the field; for example: `project_names` and `tags`.

**facets[ ].size (number, optional)** - The number of facet buckets to return with the results; defaults to the top 20 and cannot be greater than 50.

**post_filters (object[ ], optional)** - List of boolean search objects (predicates) that are joined together by the *AND* operator - they are represented as `key: value` pairs.  

*Note: Post filters are applied after the main query has executed and do not impact facets computed by main query.  This is used for the common UX use case that allows filtering by facet buckets (liken to retail shopping Web portal)*. (see [Elastic Post Filter](https://www.elastic.co/guide/en/elasticsearch/guide/current/_post_filter.html))

***The following post-filter objects are currently supported:***

**project.name** - List of project names; requires a set of comma-delimited names like so: `{"project.name": ["Big Mouse", "BD2K"]}`.

**tags.label** - List of tags; requires a set of comma-delimited tag labels like so: `{"tags.label": ["sequencing", "DNA"]}`.  

##### API Usage Example

This section provides a walk-through of the API for a concrete use case.  The examples herein were run against DDS production using the Bonsai interactive console.  The Elastic search endpoint used for the examples is: `POST /data_files/_search?pretty`.

###### The DDS Query Request

```
{
  "query_string": {
    "query": "digital coll"
  }
  "filters": [
    {"kind": ["dds-file"]},
    {"project.id": ["319e7e82-037b-4e64-af6f-5620b45e7b06", "2cdafa6b-66ce-491c-8c58-bb6430a3e969", "fea9a9f9-3428-4ee5-8a55-d5b43c19d0fa"]}
  ],
  },
  "facets": [
     {"field": "project.name", "name": "project_names", "size": 20},
     {"field": "tags.label", "name": "tags", "size": 20},
  ]
}
```

###### The DDS Query Request transformed to Elastic DSL
When the above query request is submitted to the DDS search endpoint, the request payload is transformed by the DDS application into the following Elastic DSL:

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

###### Key points about the transformation
* The `"_source": ["name", "project", "tags"]` directive is only included here for demonstration purposes - less noise when viewing search results.

* The `query": "*digital coll* *digital* *coll*"` represents the result of a *low fidelity* tokenizer (based on *white space*) to support partial (or contains matching).  For the query string, each token is wrapped with the `*` wildcard.  Only tokens of length 3 or greater will be processed - others are discarded.

*Note: We will eventually evolve to using Ngram indexing strategies, which will be more performant and provide robust results ranking. ([Elastic Ngrams for Partial Matching](https://www.elastic.co/guide/en/elasticsearch/guide/current/_ngrams_for_partial_matching.html))*

* The project filter `{"terms": {"project.id": ["319e7e82-037b ...]}}` was explicitly provided by the consumer in this example, but if not, this would be populated with all projects for which the current user has view access.

*Note: We will eventually push project ACLs into the Elastic data store, and permissions filtering will be done at search engine level.*

* For the `"aggs"` (facets), the raw non-analyzed `tags` field is specified as so: `"field": "tags.label.raw"` - this prevents the `tags` aggregate from getting represented as separate tokens.  This is not specified for `project.name` because at the time of this analysis we had not generated an associated `raw` index.

###### The DDS Response (Search Results)

The transformed Elastic DSL is passed-through to the Elastic engine and the following response payload is rendered.  For brevity, we only include specific fields (i.e. `"_source": ["name", "project", "tags"]`) and the number of results have been truncated.

```
{
   "results" : [
      {
         "name" : "road_all.csv",
         "project": {
            "name": "20161115 test",
            "id": "2cdafa6b-66ce-491c-8c58-bb6430a3e969"
          },
          "tags": [
             {"label" : "tripod2"},
             {"label" : "digital collections"},
             {"label" : "migration"}
          ]
      },
      ..................
   ],
   "facets": {
      "project_names": {
         "buckets": [
	         {
	           "key": "gcb_royallab",
	           "doc_count": 11
		      },
		      {
		        "key": "20161115",
		        "doc_count": 10
		      },
		      {
		        "key": "test",
		        "doc_count": 10
		      },
		      {
		        "key": "gcb_garmanlab2",
		        "doc_count" : 6
		      }
		   ]
	   },
	   "tags": {
	      "buckets": [
	          {
	            "key": "digital collections",
	            "doc_count": 10
	          },
	          {
	            "key": "migration",
	            "doc_count": 10
	          },
	          {
	            "key": "tripod2",
	            "doc_count": 10
	          }
          ]
      }
   }
}  
```

Keep in mind the `"project_names"` facet returned here is a bit skewed - the project name **"20161115 test"** has been split into multiple tokens, which can be resolved with the addtion of a raw not-analyzed index.

###### Applying Post Filters to DDS Query Request
The following shows how a post filter can be applied.  The main query payload is exteneded to include a `"post_filters"` directive.  This is executed after the main query executes - facets generated by main query are not affected.

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
  ],
  "post_filters": [
  	  {"tags.label": ["tripod2", "migration"]}
  ]
}
```

The post-filter is transfomed to Elastic compliant DSL and amended to the query request payload.  The resulting payload that passed-through to Elastic is as follows:

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
  },
  "post_filter": {    
     "bool" : {
        "must" : [
           {"terms": {"tags.label.raw": ["tripod2", "migration"]}}
        ]
     }
  }
}
```

Notice here that the raw non-analyzed index `tags.label.raw` is used to ensure an exact match is perfomed, not a token based match. In this case it is not relevant because the tags are single terms, but for muti-term tags, the `raw` index produces the desired results.

## Implementation View

#### Proposed Elastic Indexing Strategy

* `query_string.field`: these must be standard analyzed strings.

* `filter and post_filter`: these must be indexed with a 'field' of name '.raw', not_analyzed. These '.raw' fields are used in the Elasticsearch DSL `filter.terms` and `aggs.field`.

* `results`: these do not need to be analyzed in any specific way, unless they are query_string.field, filter, or post_filter. Elasticsearch documents should be serialized with the exact same information that is returned by the standard object serializer (not the preview), extended to include the missing elements required for filters, such as tags and meta_data, required for searches. This will ensure that the search responses can be returned from elasticsearch without a second RDBMS call for the models, in a format compatible with the format clients expect from the API call to get the resource by id.

## Process View

Add notes about performance, scalability, throughput, etc. here. These can inform future proposals to change the implementation.
