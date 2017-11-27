/*
*
* View of composite details for a "container"; the view transforms a 
* "container" at the DB layer to a "dds-folder" or a "dds-file" JSON 
* resource - retuned as the "jdoc" column - intended for client consumption 
* at the API tier or for replication into other DS data stores (i.e. Elastic).
*
*/ 

CREATE OR REPLACE VIEW v_containers AS
SELECT cn.id, cn.type, cn.project_id, cn.parent_id, cn.is_deleted,
    -- Build JSON document representation of container (dds-folder or dds-file)...
	json_build_object(
		'kind', (
		-- Transform DB type to DDS kind (i.e. dds-folder or dds-file)
		CASE WHEN cn.type = 'Folder' THEN 'dds-folder' ELSE 'dds-file' END
		), 
		'id', cn.id, 
       	'parent', (
       	-- Transform parent to DDS object format (i.e. dds-project or dds-folder)
       	CASE WHEN cn.parent_id IS NULL THEN (
		SELECT json_build_object(
			   'kind', 'dds-project', 
			   'id', project_id, 
			   'name', name
			   )
    	FROM   projects
        WHERE  id = cn.project_id) ELSE (
        SELECT json_build_object(
        	   'kind', 'dds-folder', 
        	   'id', id, 
        	   'name', name
        	   )
        FROM   containers
        WHERE  id = cn.parent_id) END
		),
	   	'name', cn.name, 
	   	'is_deleted', cn.is_deleted,
       	'project', (
       	-- Transform project to DDS object format
       	SELECT json_build_object(
       		   'id', project_id, 
       		   'name', name
       		   )
 		FROM   projects
 		WHERE  id = cn.project_id
 		),
		'ancestors', (
		-- Get the chain of ancestor DDS objects for the current container
		WITH RECURSIVE ancestors (id, type, name, parent_id, level) AS (
		  	SELECT id, type, name, -- Get the "anchor" container
		  	       parent_id, 1 
		  	FROM   containers
		    WHERE  id = cn.id
		    UNION 
		    SELECT c.id, c.type, c.name, -- Get "ancestor" containers
		           c.parent_id, an.level + 1 
		  	FROM   containers c, 
		  		   ancestors an
		    WHERE  an.parent_id = c.id 
	        )
			SELECT json_agg(
				json_build_object(
					'kind', an.type, 
					'id', an.id, 
					'name', an.name
				)
			) AS ancestors
			FROM (SELECT id, 'dds-project' AS type, name, 
		         	     null AS parent_id, null AS level
		  		  FROM   projects
		          WHERE  id = cn.project_id
		          UNION
		          SELECT id, 'dds-folder' AS type, name, 
		                 parent_id, level
		          FROM   ancestors
		          WHERE  id != cn.id -- Exclude the "anchor" container
		          ORDER BY level DESC) AS an -- Order the ancestor tree
		),
		'current_version', (
		-- Get the current version of the file (dds-file only)
		SELECT json_build_object(
			'id', fv.id, 
			'version', fv.version_number,
			'label', fv.label,
			'upload', (
			-- Get the upload object
			SELECT json_build_object(
				'id', u.id, 
				'size', u.size,
        		'storage_provider', (
        		-- Get the storage provider object
        		SELECT json_build_object(
	        			   'id', sp.id, 
	        			   'name', sp.display_name, 
	        			   'description', sp.description
					   )
 				FROM  storage_providers sp
 				WHERE sp.id = u.storage_provider_id
					),
				'hashes', (
        		-- Get the collection of hash objects
        		SELECT json_agg(
        			json_build_object(
        				'algorithm', fp.algorithm, 
        				'value', fp.value
        			)
        		)
 				FROM  fingerprints fp
 				WHERE fp.upload_id = u.id))
 			FROM uploads u
 			WHERE u.id = fv.upload_id))
 		FROM  file_versions fv
 		WHERE fv.data_file_id = cn.id
 		ORDER BY 
 			  version_number DESC LIMIT 1 -- Only return current version
 		)
	) AS jdoc
FROM containers cn
;
