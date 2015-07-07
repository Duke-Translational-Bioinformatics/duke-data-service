module DDS
  module V1
    class ProjectAffiliatesAPI < Grape::API
      desc 'Create a project affiliate' do
        detail 'Creates a project affiliate for the given payload.'
        named 'create project affiliate'
        failure [401]
      end
      params do
        requires :user
        requires :external_person
        requires :project_roles
      end
      post '/project/:project_id/affiliates', root: false do
        authenticate!
        membership_params = declared(params, include_missing: false)
        project = Project.where(uuid: params[:project_id]).first
        user = User.where(uuid: membership_params[:user][:id]).first
        membership = project.memberships.build({
          user_id: user.id
        })
        membership.save
        #membership
        {
          id: "ba33f7df-33ca-46dd-a015-92c46fdb6ba3",
          is_external: false,
          project: { id: params[:project_id] },
          user: {
              id: "c1179f73-0558-4f96-afc7-9d251e65b7bb",
              full_name: "Matthew Gardner",
              email: "mrgardner01@duke.edu"
          },
          external_person: nil,
          project_roles: [{ id: "principal_investigator", name: "Principal Investigator" }]
        }
      end

      desc 'List project affiliates' do
        detail 'Lists affiliates for a given project.'
        named 'list project affiliates'
        failure [401]
      end
      get '/project/:project_id/affiliates', root: false do
        authenticate!
#        Project.all
        {}
      end

      desc 'View project affiliate details' do
        detail 'Returns the project affiliate details for a given uuid.'
        named 'view project affiliate'
        failure [401]
      end
      get '/project/:project_id/affiliates/:id', root: false do
        authenticate!
#        Project.where(uuid: params[:id]).first
        {}
      end

      desc 'Update a project affiliate' do
        detail 'Update the project affiliate details for a given uuid.'
        named 'update project affiliate'
        failure [401]
      end
      params do
        requires :user
        requires :external_person
        requires :project_roles
      end
      put '/project/:project_id/affiliates/:id', root: false do
        authenticate!
        membership_params = declared(params, include_missing: false)
        user = User.where(uuid: membership_params[:user][:id]).first
        membership = Membership.find(params[:id])
        membership.update(
          user: user
        )
        #membership
        {
          id: membership.id,
          is_external: false,
          project: { id: membership.project.uuid },
          user: {
              id: membership.user.uuid,
              full_name: membership.user.display_name,
              email: membership.user.email
          },
          external_person: nil,
          project_roles: [{ id: "principal_investigator", name: "Principal Investigator" }]
        }
      end

      desc 'Delete a project affiliate' do
        detail 'Remove the project affiliation for a given uuid.'
        named 'delete project affiliation'
        failure [401]
      end
      delete '/project/:project_id/affiliates/:id', root: false do
        authenticate!
        membership = Membership.find(params[:id]).destroy
        body false
      end
    end
  end
end
