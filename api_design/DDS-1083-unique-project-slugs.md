# DDS-1083 Unique project slugs

## Deployment View

status: submitted for review

###### Deployment Requirements

A data migration to populate the `slug` field for existing projects should be
run on or soon after deployment.

## Logical View

#### Background

The `project.name` field is human-readable, but not unique. The `project.id` is
a 36 character long UUID that unique, but not human-readable.

#### Proposal

Add a `slug` field to `project` that is both human-readable and unique across
all projects.

## Implementation View

#### Summary of impacted APIs

|Endpoint |Description |
|---|---|
| `POST /projects/` | Create project |
| `GET /projects/` | List projects |
| `PUT /projects/{id}` | Update project |

#### API Specification

##### Create project

`POST /projects/`

###### Request Properties

- *name (string, required)* - The project name.
- *description (string, required)* - A bit of text describing the project.
- *slug (string, optional)* - A unique, short name consisting of lowercase
  letters, numbers, and underscores(\_). When omitted, the slug is automatically
  generated based on the project name.

###### Rules

When the `slug` property is set, a validation error will be raised if it is not
unique across all projects.

###### Request Example

```JSON
{
  "name": "Knockout Mouse Project (KOMP)",
  "description": "Goal of generating a targeted knockout mutation...",
  "slug": "knockout_mouse_project_komp"
}
```

###### Response Example

```JSON
{
  "kind": "dds-project",
  "id": "ca29f7df-33ca-46dd-a015-92c46fdb6fd1",
  "name": "Knockout Mouse Project (KOMP)",
  "description": "Goal of generating a targeted knockout mutation...",
  "slug": "knockout_mouse_project_komp",
  "is_deleted": false,
  "audit": { }
}
```

##### List projects

`GET /projects{?slug}`

###### Rules

When `slug` is submitted, only the project with the matching `slug` will be
returned in the `results` array. An empty array is returned when there is not
a `slug` match.

###### Response Example

```JSON
{
  "results": [
    {
      "kind": "dds-project",
      "id": "ca29f7df-33ca-46dd-a015-92c46fdb6fd1",
      "name": "Knockout Mouse Project (KOMP)",
      "description": "Goal of generating a targeted knockout mutation...",
      "slug": "knockout_mouse_project_komp",
      "is_deleted": false,
      "audit": { }
    }
  ]
}
```

##### Update project

`PUT /projects/{id}`

###### Request Properties

- *name (string, optional)* - The project name.
- *description (string, optional)* - A bit of text describing the project.
- *slug (string, optional)* - A unique, short name consisting of lowercase
  letters, numbers, and underscores(\_). When omitted, the slug is automatically
  generated based on the project name.

###### Rules

When the `slug` property is set, a validation error will be raised if it is not
unique across all projects.

###### Request Example

```JSON
{
  "slug": "knockout_mouse"
}
```

###### Response Example

```JSON
{
  "kind": "dds-project",
  "id": "ca29f7df-33ca-46dd-a015-92c46fdb6fd1",
  "name": "Knockout Mouse Project (KOMP)",
  "description": "Goal of generating a targeted knockout mutation...",
  "slug": "knockout_mouse",
  "is_deleted": false,
  "audit": { }
}
```
