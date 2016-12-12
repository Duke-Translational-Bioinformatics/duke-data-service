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
          [200, 'This will never happen'],
          [201, 'Successfully Created'],
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
        if activity.save
          activity
        else
          validation_error!(activity)
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
          [400, 'Validation Error'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (activity restricted)'],
          [404, 'Activity Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Activity UUID'
        optional :name, type: String, desc: 'The Name of the activity'
        optional :description, type: String, desc: 'The Description of the activity'
        optional :started_on, type: DateTime, desc: "DateTime when the activity started"
        optional :ended_on, type: DateTime, desc: "DateTime when the activity ended"
      end
      put '/activities/:id', root: false do
        authenticate!
        activity_params = declared(params, {include_missing: false}, [:name, :description, :started_on, :ended_on])
        activity = hide_logically_deleted Activity.find(params[:id])
        authorize activity, :update?
        if activity.update(activity_params)
          activity
        else
          validation_error!(activity)
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
        activity.update(is_deleted: true)
        body false
      end
    end
  end
end
