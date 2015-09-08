module DDS
  module V1
    class AuthRolesAPI < Grape::API
      desc 'List authorization roles' do
        detail 'Lists authorization roles for a given context.'
        named 'list authorization roles'
        failure [401]
      end
      get '/:context/auth_roles', root: false do
        authenticate!
        return {results: [
          {
           id: "project_admin",
           name: "Project Admin",
           description: "Can update project details, delete project, manage project level permissions and perform all file operations",
           permissions: [{ "id": "view_project"}, {"id": "update_project"}, {"id": "delete_project"}, {"id": "manage_project_permissions"}, {"id": "download_file"}, {"id": "create_file"}, {"id": "update_file"}, {"id": "delete_file"}],
           contexts: [ "project" ],
           is_deprecated: false
         },
          {
           id: "project_viewer",
           name: "Project Viewer",
           description: "Can only view project and file meta-data",
           permissions: [{ "id": "view_project" }],
           contexts: [ "project" ],
           is_deprecated: false
         },
          {
           id: "file_downloader",
           name: "File Downloader",
           description: "Can download files",
           permissions: [{ "id": "view_project"}, {"id": "download_file" }],
           contexts: [ "project" ],
           is_deprecated: false
         },
          {
           id: "file_uploader",
           name: "File Uploader",
           description: "Can upload files",
           permissions: [{ "id": "view_project"}, {"id": "create_file" }],
           contexts: [ "project" ],
           is_deprecated: false
         },
          {
           id: "file_editor",
           name: "File Editor",
           description: "Can view, download, create, update and delete files",
           permissions: [{ "id": "view_project"}, {"id": "download_file"}, {"id": "create_file"}, {"id": "update_file"}, {"id": "delete_file"}],
           contexts: [ "project" ],
           is_deprecated: false
          }
          ]}
      end
      desc 'List details of a single authorization role' do
        detail 'Returns the details of an auth role for a given text id.'
        named 'view authorization role'
        failure [401]
      end
      get '/:context/auth_roles/:id', root: false do
        authenticate!
        AuthRole.find(params[:id])
      end
    end
  end
end
