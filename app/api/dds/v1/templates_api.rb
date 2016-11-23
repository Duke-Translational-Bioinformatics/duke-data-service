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
      params do
        optional :name_contains, type: String, desc: 'list templates whose name contains the specified string'
      end
      get '/templates', root: 'results' do
        authenticate!
        template_params = declared(params, include_missing: false)
        if name_contains = template_params[:name_contains]
          template = Template.where(Template.arel_table[:name].matches("%#{name_contains}%"))
        else
          Template.all
        end

      end

      desc 'View template details' do
        detail 'Returns the template details for a given UUID.'
        named 'view template'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (template restricted)'],
          [404, 'Template Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Template UUID'
      end
      get '/templates/:id', root: false do
        authenticate!
        template = Template.find(params[:id])
        template
      end

      desc 'Update template' do
        detail 'Updates template UUID.'
        named 'update template'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (template restricted)'],
          [400, 'Validation Error'],
          [404, 'Template Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Template UUID'
        optional :name, type: String, desc: 'The Name of the template'
        optional :label, type: String, desc: 'The Label of the template'
        optional :description, type: String, desc: 'The Description of the template'
      end
      put '/templates/:id', root: false do
        authenticate!
        template_params = declared(params, {include_missing: false}, [:name, :label, :description])
        template =  Template.find(params[:id])
        authorize template, :update?
        if template.update(template_params)
          template
        else
          validation_error!(template)
        end
      end

      desc 'Delete a template' do
        detail 'Deletes a template.'
        named 'delete template'
        failure [
          [204, 'Successfully Deleted'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (template restricted)'],
          [404, 'Template Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Template UUID'
      end
      delete '/templates/:id', root: false do
        authenticate!
        template = Template.find(params[:id])
        authorize template, :destroy?
        if template.destroy
          body false
        else
          validation_error!(template)
        end
      end
    end
  end
end
