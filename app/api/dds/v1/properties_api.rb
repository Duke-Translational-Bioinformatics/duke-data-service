module DDS
  module V1
    class PropertiesAPI < Grape::API
      desc 'Create property' do
        detail 'Creates a property.'
        named 'create property'
        failure [
          [200, 'This will never happen'],
          [201, 'Successfully Created'],
          [400, 'Validation error'],
          [401, 'Unauthorized']
        ]
      end
      params do
        requires :key, type: String, desc: "The unique key of the property"
        requires :label, type: String, desc: "A short display label for the property"
        requires :description, type: String, desc: "A verbose description of the property"
        requires :type, type: String, desc: "The datatype of the key’s value; currenty only the Elasticsearch core datatypes are supported"
      end
      post '/templates/:template_id/properties', root: false do
        authenticate!
        property_params = declared(params, {include_missing: false}, [:key, :label, :description, :type])
        template = Template.find(params[:template_id])
        property = template.properties.build(
          key: property_params[:key],
          label: property_params[:label],
          description: property_params[:description],
          data_type: property_params[:type],
        )
        authorize property, :create?
        if property.save
          property
        else
          validation_error!(property)
        end
      end

      desc 'List properties' do
        detail 'List properties.'
        named 'list properties'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      get '/templates/:template_id/properties', root: 'results' do
        authenticate!
        template = Template.find(params[:template_id])
        template.properties
      end

      desc 'View property details' do
        detail 'Returns the property details for a given UUID.'
        named 'view property'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (property restricted)'],
          [404, 'Property Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Property UUID'
      end
      get '/template_properties/:id', root: false do
        authenticate!
        property = Property.find(params[:id])
        property
      end

      desc 'Update property' do
        detail 'Updates property for given UUID.'
        named 'update property'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (property restricted)'],
          [400, 'Validation Error'],
          [404, 'Property Does not Exist']
        ]
      end
      params do
        optional :key, type: String, desc: "The unique key of the property"
        optional :label, type: String, desc: "A short display label for the property"
        optional :description, type: String, desc: "A verbose description of the property"
        optional :type, type: String, desc: "The datatype of the key’s value; currenty only the Elasticsearch core datatypes are supported"
      end
      put '/template_properties/:id', root: false do
        authenticate!
        property_params = declared(params, {include_missing: false}, [:key, :label, :description, :type])
        property =  Property.find(params[:id])
        authorize property, :update?
        property_params[:data_type] = property_params.delete(:type) if property_params[:type]
        if property.update(property_params)
          property
        else
          validation_error!(property)
        end
      end
    end
  end
end
