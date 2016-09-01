module DDS
  module V1
    class TemplatesAPI < Grape::API
      desc 'Create template' do
        detail 'Creates a template.'
        named 'create template'
        failure [
          [200, 'This will never happen'],
          [201, 'Successfully Created'],
          [400, 'Validation error'],
          [401, 'Unauthorized']
        ]
      end
      params do
        requires :name, type: String, desc: "The unique name of the template"
        requires :label, type: String, desc: "A short display label for the template"
        optional :description, type: String, desc: "A verbose description of the template"
      end
      post '/templates', root: false do
        authenticate!
        template_params = declared(params, {include_missing: false}, [:name, :label, :description])
        template = Template.new(template_params)
        template.creator = current_user
        if template.save
          template
        else
          validation_error!(template)
        end
      end

      desc 'List templates' do
        detail 'List templates.'
        named 'list templates'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      get '/templates', root: 'results' do
        authenticate!
        Template.all
      end
    end
  end
end
