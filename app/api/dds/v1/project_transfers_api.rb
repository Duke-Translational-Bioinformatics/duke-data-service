module DDS
  module V1
    class ProjectTransfersAPI < Grape::API
      before do
        not_implemented_error! if ENV['SKIP_PROJECT_TRANSFERS']
      end
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
          [401, 'Unauthorized'],
          [404, 'Project does not exist']
        ]
      end
      get '/projects/:project_id/transfers', root: 'results' do
        authenticate!
        project = Project.find(params[:project_id])
        policy_scope(ProjectTransfer).where(project: project)
      end

      desc 'View a project transfer' do
        detail 'Used to view an instance of a project transfer.'
        named 'view a project transfer'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Project transfer does not exist']
        ]
      end
      get '/project_transfers/:id', root: false do
        authenticate!
        project_transfer = ProjectTransfer.find(params[:id])
        authorize project_transfer, :show?
        project_transfer
      end

      desc 'Reject a project transfer' do
        detail 'Reject a pending project transfer.'
        named 'reject a project transfer'
        failure [
          [200, 'Success'],
          [400, 'Validation Error'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Project transfer does not exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'The unique id of the project transfer.'
        optional :status_comment, type: String, desc: 'An optional comment that can be provided.'
      end
      put '/project_transfers/:id/reject', root: false do
        authenticate!
        project_transfer = ProjectTransfer.find(params[:id])
        project_transfer_params = declared(params, {include_missing: false}, [:status_comment])
        project_transfer.status = 'rejected'
        project_transfer.status_comment = project_transfer_params[:status_comment] if project_transfer_params[:status_comment]
        authorize project_transfer, :update?
        if project_transfer.save
          project_transfer
        else
          validation_error!(project_transfer)
        end
      end

      desc 'Cancel a project transfer' do
        detail 'Cancel a pending project transfer.'
        named 'cancel a project transfer'
        failure [
          [200, 'Success'],
          [400, 'Validation Error'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Project transfer does not exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'The unique id of the project transfer.'
        optional :status_comment, type: String, desc: 'An optional comment that can be provided.'
      end
      put '/project_transfers/:id/cancel', root: false do
        authenticate!
        project_transfer = ProjectTransfer.find(params[:id])
        project_transfer_params = declared(params, {include_missing: false}, [:status_comment])
        project_transfer.status = 'canceled'
        project_transfer.status_comment = project_transfer_params[:status_comment] if project_transfer_params[:status_comment]
        authorize project_transfer, :destroy?
        if project_transfer.save
          project_transfer
        else
          validation_error!(project_transfer)
        end
      end

      desc 'Accept a project transfer' do
        detail 'Accept a pending project transfer.'
        named 'accept a project transfer'
        failure [
          [200, 'Success'],
          [400, 'Validation Error'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Project transfer does not exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'The unique id of the project transfer.'
        optional :status_comment, type: String, desc: 'An optional comment that can be provided.'
      end
      put '/project_transfers/:id/accept', root: false do
        authenticate!
        project_transfer = ProjectTransfer.find(params[:id])
        project_transfer_params = declared(params, {include_missing: false}, [:status_comment])
        authorize project_transfer, :update?
        project_transfer.status = 'accepted'
        project_transfer.status_comment = project_transfer_params[:status_comment] if project_transfer_params[:status_comment]
        if project_transfer.save
          project_transfer
        else
          validation_error!(project_transfer)
        end
      end
    end
  end
end
