module DDS
  module V1
    class MetaTemplatesAPI < Grape::API
      desc 'Create object metadata' do
        detail 'Creates object metadata.'
        named 'create object metadata'
        failure [
          [200, 'This will never happen'],
          [201, 'Successfully Created'],
          [400, 'Validation error'],
          [401, 'Unauthorized'],
          [404, 'Object or template does not exist']
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
          validation_error!(meta_template)
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
    end
  end
end
