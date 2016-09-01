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

      desc 'View metadata template details' do
        detail 'Returns the metadata template details for a given UUID.'
        named 'view metadata template'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (metadata_template restricted)'],
          [404, 'Metadata Template Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Metadata template UUID'
      end
      get '/templates/:id', root: false do
        authenticate!
        template = Template.find(params[:id])
        template
      end

      desc 'Delete a metadata template' do
        detail 'Deletes a metadata template.'
        named 'delete metadata template'
        failure [
          [204, 'Successfully Deleted'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (metadata_template restricted)'],
          [404, 'Metadata Template Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Metadata Template UUID'
      end
      delete '/templates/:id', root: false do
        authenticate!
        template = Template.find(params[:id])
        authorize template, :destroy?
        template.destroy
        body false
      end

    end
  end
end
