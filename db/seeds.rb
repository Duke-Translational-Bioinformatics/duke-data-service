# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
[
    {
      id: "project_admin",
      name: "Project Admin",
      description: "Can update project details, delete project, manage project level permissions and perform all file operations",
      contexts: %w(project),
      permissions: %w(view_project update_project delete_project manage_project_permissions download_file create_file update_file delete_file)
    },
    {
      id: "project_viewer",
      name: "Project Viewer",
      description: "Can only view project and file meta-data",
      contexts: %w(project),
      permissions: %w(view_project)
    },
    {
      id: "file_downloader",
      name:	"File Downloader",
      description:	"Can download files",
      contexts: %w(project),
      permissions: %w(view_project download_file)
    },
    {
      id: "file_editor",
      name: "File Editor",
      description: "Can view download create update and delete files",
      contexts: %w(project),
      permissions: %w(view_project download_file create_file update_file delete_file)
    }
].each do |role|
  AuthRole.create(role)
end

[
  {
    id: 'principal_investigator',
    name: 'Principal Investigator',
    description: "Lead investigator for the research project",
    is_depricated: false
  },
  {
    id: "research_coordinator",
    name: "Research Coordinator",
    description: "Coordinator for the research project",
    is_depricated: false
  }
].each do |role|
  ProjectRole.create(role)
end
