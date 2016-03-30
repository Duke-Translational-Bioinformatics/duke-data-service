var Dredd = require('dredd');

// allow self-signed certs
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// suppress warning message if more than 10 listeners are added to an event - this is needed here to suppress
// warning messages from the node-rest-client package...
require('events').EventEmitter.defaultMaxListeners = Infinity;

configuration = {
  server: process.env.HOST_NAME, // your URL to API endpoint the tests will run against
  //For debug: export HOST_NAME=https://dukeds-dev.herokuapp.com/api/v1
  //For debug: export HOST_NAME=https://uatest.dataservice.duke.edu/api/v1
  //Get JWT: https://dukeds-dev.herokuapp.com/apiexplorer
  //export MY_GENERATED_JWT=
  options: {

    'path': ['./apiary.apib'],  // Required Array if Strings; filepaths to API Blueprint files, can use glob wildcards

    'dry-run': false, // Boolean, do not run any real HTTP transaction
    'names': false,   // Boolean, Print Transaction names and finish, similar to dry-run

    'level': 'info', // String, log-level (info, silly, debug, verbose, ...)
    'silent': false, // Boolean, Silences all logging output

    'only': [//01_auth_hooks.js
             //"Authorization Roles > Authorization Roles collection > List roles",
             //"Authorization Roles > Authorization Role instance > View role",
             //14_software_agents.js
            //  "Software Agents > Software Agents collection > Create software agent",
            //  "Software Agents > Software Agents collection > List software agents",
            //  "Software Agents > Software Agent instance > View software agent",
            //  "Software Agents > Software Agent instance > Update software agent",
            //  "Software Agents > Software Agent instance > Delete software agent",
            //  "Software Agents > Software Agent API Key > Generate software agent API key",
            //  "Software Agents > Software Agent API Key > View software agent API key",
            //  "Software Agents > Software Agent API Key > Delete software agent API key",
            //  "Software Agents > Software Agent Access Token > Get software agent access token",
            //15_current_user_api_hooks.js
            // "Current User > Current User instance > View current user",
            // "Current User > Current User instance > Current user usage",
            // "Current User > Current User Secret Key > Generate current user API key",
            // "Current User > Current User Secret Key > View current user API key",
            // "Current User > Current User Secret Key > Delete current user API key",
            //03_users_hooks.js
            // "Users > Users collection > List users",
            // "Users > User instance > View user",
            //04_system_permissions_hooks.js
            // "System Permissions > System Permissions collection > List system permissions",
            // "System Permissions > System Permission instance > Grant system permission",
            // "System Permissions > System Permission instance > View system permission",
            // "System Permissions > System Permission instance > Revoke system permission",
            //05_projects_hooks.js
            // "Projects > Projects collection > Create project",
            // "Projects > Projects collection > List projects",
            // "Projects > Project instance > View project",
            // "Projects > Project instance > Update project",
            // "Projects > Project instance > Delete project",
            //06_project_permissions_hooks.js
            // "Project Permissions > Project Permissions collection > List project permissions",
            // "Project Permissions > Project Permission instance > Grant project permission",
            // "Project Permissions > Project Permission instance > View project permission",
            // "Project Permissions > Project Permission instance > Revoke project permission",
            //07_project_roles_hooks.js
            // "Project Roles > Project Roles collection > List project roles",
            // "Project Roles > Project Role instance > View project role",
            //08_affiliates_hooks.js
            // "Affiliates > Affiliates collection > List affiliates",
            // "Affiliates > Affiliate instance > Associate affiliate",
            // "Affiliates > Affiliate instance > View affiliate",
            // "Affiliates > Affiliate instance > Delete affiliate",
            //09_storage_providers_hooks.js
            // "Storage Providers > Storage Providers collection > List storage providers",
            // "Storage Providers > Storage Provider instance > View storage provider",
            //10_folders_hooks.js
            // "Folders > Folders collection > Create folder",
            // "Folders > Folder instance > View folder",
            // "Folders > Folder instance > Delete folder",
            // "Folders > Folder instance > Move folder",
            // "Folders > Folder instance > Rename folder",
            //11_uploads_hooks.js
            // "Uploads > Uploads collection > Initiate chunked upload",
            // "Uploads > Uploads collection > List chunked uploads",
            // "Uploads > Upload instance > View chunked upload",
            // "Uploads > Upload instance > Get pre-signed chunk URL",
            // "Uploads > Upload instance > Complete chunked file upload",
            // "Uploads > Upload instance > Report server computed hash",
            //16_search_uploads.js
            // "Search Uploads > Search uploads > Search uploads",
            //12_files_hooks.js
            "Files > Files collection > Create file",
            "Files > File instance > View file",
            "Files > File instance > Update file",
            "Files > File instance > Delete file",
            "Files > File instance > Get file download URL",
            "Files > File instance > Move file",
            "Files > File instance > Rename file",
            //17_file_versions.js
            // "File Versions > File Versions collection > List file versions",
            // "File Versions > File Version instance > View file version",
            // "File Versions > File Version instance > Update file version",
            // "File Versions > File Version instance > Delete file version",
            // "File Versions > File Version instance > Get file version download URL",
            //13_search_project_folder_hooks.js
            // "Search Children > Search project children > Search project children",
            // "Search Children > Search folder children > Search folder children",
            //18_provenance_activities.js
            // "Provenance Activities > Activities collection > List activities",
            // "Provenance Activities > Activities instance > View activity",
            // "Provenance Activities > Activities instance > Update activity",
            // "Provenance Activities > Activities instance > Delete activity",
            //19_provenance_relations.js
            // "Provenance Relations > Relations collection > Create used relation",
            // "Provenance Relations > Relations collection > Create generated relation",
            // "Provenance Relations > Relations collection > List provenance relations",
            // "Provenance Relations > Relation instance > View relation",
            // "Provenance Relations > Relation instance > Delete relation",
            //20_search_provenance.js
            // "Search Provenance > Search Provenance > Search Provenance",



            ], // Array of Strings, run only transaction that match these names

    'header': ['Accept: application/json', 'Authorization: '.concat(process.env.MY_GENERATED_JWT)], // Array of Strings, these strings are then added as headers (key:value) to every transaction
    'user': null,    // String, Basic Auth credentials in the form username:password

    'hookfiles': [ //'99_learnclient.js',
                  // '01_auth_hooks.js',
                  // '02_current_user_hooks.js',
                  // '03_users_hooks.js',
                  // '04_system_permissions_hooks.js',
                  // '05_projects_hooks.js',
                  // '06_project_permissions_hooks.js',
                  // '07_project_roles_hooks.js',
                  // '08_affiliates_hooks.js',
                  // '09_storage_providers_hooks.js',
                  // '10_folders_hooks.js',
                  // '11_uploads_hooks.js',
                  '12_files_hooks.js',
                  // '13_search_project_folder_hooks.js',
                  // '14_software_agents.js',
                  // '15_current_user_api_hooks.js',
                  // '16_search_uploads.js',
                  // '17_file_versions.js',
                  // '18_provenance_activities.js',
                  // '19_provenance_relations.js',
                  // '20_search_provenance.js',
                ], // Array of Strings, filepaths to files containing hooks (can use glob wildcards)

    'reporter': [], // Array of possible reporters, see folder src/reporters

    'output': [],    // Array of Strings, filepaths to files used for output of file-based reporters

    'inline-errors': false, // Boolean, If failures/errors are display immediately in Dredd run

    'color': true,
    'timestamp': false
  }
  // 'emitter': EventEmitterInstance // optional - listen to test progress, your own instance of EventEmitter

  // 'hooksData': {
  //   'pathToHook' : '...'
  // }

  // 'data': {
  //   'path/to/file': '...'
  //}
}

var dredd = new Dredd(configuration);

dredd.run(function (err, stats) {
  // uncomment for production stop
  // if (stats.failures>0 | stats.error>0) process.exit(1);
  // uncomment for production uninterrupted
  if (stats.failures>0 | stats.error>0) process.exit(0);
});
