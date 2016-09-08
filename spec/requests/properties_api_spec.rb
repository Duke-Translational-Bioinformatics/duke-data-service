require 'rails_helper'

describe DDS::V1::PropertiesAPI do
  include_context 'with authentication'

  let(:template) { property.template }
  let(:property) { FactoryGirl.create(:property) }
  let(:other_property) { FactoryGirl.create(:property) }
  let(:property_stub) { FactoryGirl.build(:property) }
  let(:system_permission) { FactoryGirl.create(:system_permission, user: current_user) }

  let(:resource_class) { Property }
  let(:resource_serializer) { PropertySerializer }
  let!(:resource) { property }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { system_permission }
  let(:resource_stub) { property_stub }

  describe 'Properties collection' do
    let(:url) { "/api/v1/templates/#{template_id}/properties" }
    let(:template_id) { template.id }

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }
      let!(:payload) {{
        key: payload_key,
        label: resource_stub.label,
        description: resource_stub.description,
        type: resource_stub.data_type
      }}
      let(:payload_key) { resource_stub.key }

      it_behaves_like 'a creatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      context 'with blank key' do
        let(:payload_key) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'with existing key' do
        let(:payload_key) { resource.key }
        it_behaves_like 'a validated resource'
      end

      it_behaves_like 'an identified resource' do
        let(:template_id) { "notexist" }
        let(:resource_class) { Template }
      end
    end

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_property
        ] }
      end
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:template_id) { "notexist" }
        let(:resource_class) { Template }
      end
    end
  end

  describe 'Property instance' do
    let(:url) { "/api/v1/template_properties/#{resource_id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
      it_behaves_like 'a software_agent accessible resource'
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let(:payload) {{
        key: payload_key,
        label: resource_stub.label,
        description: resource_stub.description,
        type: resource_stub.data_type
      }}
      let(:payload_key) { resource_stub.key }

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authorized resource' do
        let(:resource) { other_property }
      end
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
      it_behaves_like 'a software_agent accessible resource'

      context 'with blank key' do
        let(:payload_key) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'with existing key' do
        let(:payload_key) { other_property.key }
        it_behaves_like 'a validated resource'
      end
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
    end
  end
end
