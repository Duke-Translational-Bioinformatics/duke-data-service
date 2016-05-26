module DDS
  module V1
    class RelationsAPI < Grape::API

      desc 'Create used relation' do
        detail 'Creates a WasUsedBy relationship.'
        named 'create used relation'
        failure [
          [200, 'This will never actually happen'],
          [201, 'Created Successfully'],
          [400, 'Activity and Entity are required'],
          [401, 'Unauthorized'],
          [403, 'Forbidden']
        ]
      end
      params do
        requires :activity, desc: "Activity", type: Hash do
          requires :id, type: String, desc: "Activity UUID"
        end
        requires :entity, desc: "Entitiy", type: Hash do
          requires :kind, type: String, desc: "Entity kind"
          requires :id, type: String, desc: "Entity UUID"
        end
      end
      post '/relations/used', root: false do
        authenticate!
        used_relation_params = declared(params, include_missing: false)
        activity = Activity.find(used_relation_params[:activity][:id])
        #todo change this when we allow other entities to be used by activities
        entity = FileVersion.find(used_relation_params[:entity][:id])

        used_relation = UsedProvRelation.new(
          relatable_from: activity,
          creator: current_user,
          relatable_to: entity
        )
        authorize used_relation, :create?
        Audited.audit_class.as_user(current_user) do
          if used_relation.save
            annotate_audits [used_relation.audits.last]
            used_relation
          else
            validation_error!(activity)
          end
        end
      end

    end
  end
end
