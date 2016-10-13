module DDS
  module V1
    class ProjectTransfersAPI < Grape::API
      desc 'Initiate a project transfer' do
        detail 'Initiates a project transfer from the current owner to a new owner or list of owners.'
        named 'initiate project transfer'
        failure [
          [200, 'This will never actually happen'],
          [201, 'Created Successfully'],
          [400, 'Project Transfer Already Exists'],
          [401, 'Unauthorized'],
          [403, 'Forbidden']
        ]
      end
      params do
        requires :project_id, type: String, desc: "The ID of the Project"
        requires :to_users, type: Array, desc: "The list of users to transfer project ownership to." do
          requires :id, type: String, desc: "The unique id of a user"
        end
      end
      post '/projects/:project_id/transfers', root: false do
        authenticate!
        project_transfer_params = declared(params, include_missing: false)
        project = Project.find(params[:project_id])
        project_transfer = ProjectTransfer.new({
          project: project,
          from_user: current_user,
          status: 'pending'
          })
        project_transfer_params[:to_users].each do |to_user|
          project_transfer.project_transfer_users.build({
            to_user_id: to_user[:id]
            })
        end
        authorize project_transfer, :create?
        if project_transfer.save
          project_transfer
        else
          validation_error!(project_transfer)
        end
      end

      desc 'List project transfers' do
        detail 'list project transfers'
        named 'list project transfers'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      get '/projects/:project_id/transfers', root: 'results' do
        authenticate!
        project = Project.find(params[:project_id])
        policy_scope(ProjectTransfer).where(project: project)
     end
    end
  end
end
