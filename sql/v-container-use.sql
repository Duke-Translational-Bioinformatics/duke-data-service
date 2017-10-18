/*
* Example of how "containers" view could be utilized at the
* API implementation tier...
*
* These examples use the "Sprawl" project in UA test.
*/

--
-- Get ALL the containers (recursive) for a PROJECT
--
-- GET /projects/{id}/children?recursive=true
--
SELECT jdoc 
FROM   v_containers
WHERE  project_id = '5e9342df-4d40-403e-9334-976b9dfc1d1b' AND
       NOT is_deleted
       LIMIT 5;

--
-- Get the containers (immediate children) for a PROJECT
--
-- GET /projects/{id}/children?recursive=false
--
SELECT jdoc 
FROM   v_containers
WHERE  project_id = '5e9342df-4d40-403e-9334-976b9dfc1d1b' AND
 	   parent_id IS NULL AND -- project is immediate parent
       NOT is_deleted
       LIMIT 5;

--
-- Get ALL the containers (recursive) for a FOLDER
--
-- GET /folders/{id}/children?recursive=true
--
SELECT jdoc 
FROM   v_containers
WHERE  project_id = '5e9342df-4d40-403e-9334-976b9dfc1d1b' AND
	   -- use jsonb containment to find folder in ancestor tree
       jdoc::jsonb @> '{"ancestors": [{"id": "66437bbc-1e31-4278-a1c9-a0ff18f2f42f"}]}' AND
       NOT is_deleted
       LIMIT 5;

--
-- Get the containers (immediate children) for a FOLDER
--
-- GET /folders/{id}/children?recursive=false
--
SELECT jdoc 
FROM   v_containers
WHERE  parent_id = '66437bbc-1e31-4278-a1c9-a0ff18f2f42f' AND
       NOT is_deleted
       LIMIT 5;
