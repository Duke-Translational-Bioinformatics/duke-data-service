module DDS
  module V1
    class MetaTemplatesAPI < Grape::API
      desc 'View all object metadata' do
        detail 'Used to retrieve all metadata associated with a DDS object, optionally find a template instance by name.'
        named 'view object metadata'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [404, 'Object or template does not exist']
        ]
      end
      params do
        optional :meta_template_name, type: String, desc: "The unique meta_template_name of the template; performs an exact match."
      end
      get '/meta/:object_kind/:object_id', root: 'results' do
        authenticate!
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        templatable_object = object_kind.find(params[:object_id])
        meta_params = declared(params, {include_missing: false})
        meta_templates = policy_scope(MetaTemplate).where(templatable: templatable_object)
        if name = meta_params[:meta_template_name]
          meta_templates = meta_templates.joins(:template).where(templates: {name: name})
        end
        meta_templates
      end

      desc 'Create object metadata' do
        detail 'Creates object metadata.'
        named 'create object metadata'
        failure [
          [200, 'This will never happen'],
          [201, 'Successfully Created'],
          [400, 'Validation error'],
          [401, 'Unauthorized'],
          [404, 'Object or template does not exist'],
          [409, 'Template instance already exists for the DDS object']
        ]
      end
      params do
        requires :properties, type: Array, desc: "A list of the key:value pairs to set for the template instance." do
          requires :key, type: String, desc: "The property key to set"
          requires :value, type: String, desc: "The key value"
        end
      end
      post '/meta/:object_kind/:object_id/:template_id', root: false do
        authenticate!
        meta_params = declared(params, {include_missing: false})

        object_kind = KindnessFactory.by_kind(params[:object_kind])
        templatable_object = object_kind.find(params[:object_id])
        template = Template.find(params[:template_id])

        meta_template = MetaTemplate.new(
          template: template,
          templatable: templatable_object
        )

        meta_params[:properties].each do |property_params|
          meta_template.meta_properties.build(property_params)
        end

        authorize meta_template, :create?

        if meta_template.save
          meta_template
        else
          if meta_template.errors.added? :template, :taken
            error!({
              error: '409',
              code: "not_provided",
              reason: 'unique conflict',
              suggestion: 'Resubmit as an update request'
            }, 409)
          else
            validation_error!(meta_template)
          end
        end
      end

      desc 'View object metadata' do
        detail 'Used to retrieve the metadata template instance for a corresponding DDS object.'
        named 'view object metadata'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Object or Template does not exist']
        ]
      end
      get '/meta/:object_kind/:object_id/:template_id', root: false do
        authenticate!

        object_kind = KindnessFactory.by_kind(params[:object_kind])
        templatable_object = object_kind.find(params[:object_id])
        template = Template.find(params[:template_id])
        meta_template = MetaTemplate.where(templatable: templatable_object, template: template).take!
        meta_template
      end

      desc 'Update object metadata' do
        detail 'Updates object metadata'
        named 'update object metadata'
        failure [
          [200, 'Success'],
          [400, 'Validation Error'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Object or Template does not exist']
        ]
      end
      params do
        requires :properties, type: Array, desc: "A list of the key:value pairs to set for the template instance." do
          requires :key, type: String, desc: "The property key to set"
          requires :value, type: String, desc: "The key value"
        end
      end
      put '/meta/:object_kind/:object_id/:template_id', root: false do
        authenticate!
        meta_params = declared(params, {include_missing: false})

        object_kind = KindnessFactory.by_kind(params[:object_kind])
        templatable_object = object_kind.find(params[:object_id])
        template = Template.find(params[:template_id])
        meta_template = MetaTemplate.where(templatable: templatable_object, template: template).take!

        existing_keys = meta_template.meta_properties.collect {|mp| mp.property.key}
        meta_params[:properties].each do |property_params|
          if meta_property_index = existing_keys.index(property_params[:key])
            meta_template.meta_properties[meta_property_index].value = property_params[:value]
          else
            meta_template.meta_properties.build(property_params)
          end
        end

        if meta_template.save
          meta_template
        else
          validation_error!(meta_template)
        end
      end

      desc 'Delete objet metadata' do
        detail 'Deletes objet metadata'
        named 'delete objet metadata'
        failure [
          [200, "This will never happen"],
          [204, 'Successfully Deleted'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Object or template does not exist']
        ]
      end
      delete '/meta/:object_kind/:object_id/:template_id', root: false do
        authenticate!
        meta_params = declared(params, {include_missing: false})

        object_kind = KindnessFactory.by_kind(params[:object_kind])
        templatable_object = object_kind.find(params[:object_id])
        template = Template.find(params[:template_id])
        meta_template = MetaTemplate.where(templatable: templatable_object, template: template).take!
        authorize meta_template, :destroy?
        meta_template.destroy
        body false
      end
    end
  end
end
