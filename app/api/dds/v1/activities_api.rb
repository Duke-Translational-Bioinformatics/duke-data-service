module DDS
  module V1
    class ActivitiesAPI < Grape::API
      desc 'List activities' do
        detail 'Lists all activities'
        named 'list activities'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden']
        ]
      end
      get '/activities', root: 'results' do
        authenticate!
        authorize Activity.new, :index?
        policy_scope(Activity).where(is_deleted: false)
      end

      desc 'Create a activity' do
        detail 'Creates an activity for the given payload.'
        named 'create activity'
        failure [
          [200, 'This will never actually happen'],
          [201, 'Created Successfully'],
          [400, 'Activity requires a name'],
          [401, 'Unauthorized'],
          [403, 'Forbidden']
        ]
      end
      params do
        requires :name, type: String, desc: 'The Name of the activity'
        optional :description, type: String, desc: 'The Description of the activity'
        optional :started_on, type: DateTime, desc: "DateTime when the activity started"
        optional :ended_on, type: DateTime, desc: "DateTime when the activity ended"
      end
      post '/activities', root: false do
        authenticate!
        activity_params = declared(params, include_missing: false)
        activity = Activity.new({
          name: activity_params[:name],
          description: activity_params[:description],
          started_on: activity_params[:started_on],
          ended_on: activity_params[:ended_on],
          creator: current_user
        })
        authorize activity, :create?
        Audited.audit_class.as_user(current_user) do
          if activity.save
            uaa = AgentActivityAssociation.create(agent: current_user, activity: activity)
            audits = [activity.audits.last, uaa.audits.last]
            if current_user.current_software_agent
              saa = AgentActivityAssociation.create(agent: current_user.current_software_agent, activity: activity)
              audits << saa.audits.last
            end
            annotate_audits audits
            activity
          else
            validation_error!(activity)
          end
        end
      end

      desc 'View activity details' do
        detail 'Returns the activity details for a given UUID.'
        named 'view activity'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Activity Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Activity UUID'
      end
      get '/activities/:id', root: false do
        authenticate!
        activity = Activity.find(params[:id])
        authorize activity, :show?
        activity
      end

      desc 'Update Activity' do
        detail 'Updates the activity details for a given UUID.'
        named 'update activity'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (activity restricted)'],
          [400, 'Validation Error'],
          [404, 'Activity Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Activity UUID'
        requires :name, type: String, desc: 'The Name of the activity'
        optional :description, type: String, desc: 'The Description of the activity'
        optional :started_on, type: DateTime, desc: "DateTime when the activity started"
        optional :ended_on, type: DateTime, desc: "DateTime when the activity ended"
      end
      put '/activities/:id', root: false do
        authenticate!
        activity_params = declared(params, include_missing: false)
        activity = hide_logically_deleted Activity.find(params[:id])
        authorize activity, :update?
        Audited.audit_class.as_user(current_user) do
          if activity.update(activity_params)
            annotate_audits [activity.audits.last]
            activity
          else
            validation_error!(activity)
          end
        end
      end

      desc 'Delete a Activity' do
        detail 'Marks an activity as being deleted.'
        named 'delete activity'
        failure [
          [204, 'Successfully Deleted'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (activity restricted)'],
          [404, 'Activity Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Activity UUID'
      end
      delete '/activities/:id', root: false do
        authenticate!
        activity = hide_logically_deleted Activity.find(params[:id])
        authorize activity, :destroy?
        Audited.audit_class.as_user(current_user) do
          activity.update(is_deleted: true)
          annotate_audits [activity.audits.last]
        end
        body false
      end
    end
  end
end
