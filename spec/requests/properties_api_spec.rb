require 'rails_helper'

describe DDS::V1::PropertiesAPI do
  include_context 'with authentication'

  let(:template) { property.template }
  let(:property) { FactoryGirl.create(:property) }
  let(:sibling_property) { FactoryGirl.create(:property, template: template) }
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
    let(:url) { "/api/v1/templates/#{template_id}/properties#{query_params}" }
    let(:query_params) { '' }
    let(:template_id) { template.id }

    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
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
      subject { get(url, headers: headers) }

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

      context 'with key query parameter' do
        let(:query_params) { "?key=#{key}" }

        context 'when empty string' do
          let(:key) { '' }
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [
            ] }
            let(:unexpected_resources) { [
              property,
              other_property
            ] }
          end
        end
        context 'when string without matches' do
          let(:key) { 'key' }
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [
            ] }
            let(:unexpected_resources) { [
              property,
              other_property
            ] }
          end
        end

        context 'when string with a match' do
          let(:key) { property.key }
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [
              property
            ] }
            let(:unexpected_resources) { [
              other_property
            ] }
          end
        end

        context 'when upcase string' do
          let(:key) { property.key.upcase }
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [
            ] }
            let(:unexpected_resources) { [
              property,
              other_property
            ] }
          end
        end
      end
    end
  end

  describe 'Property instance' do
    let(:url) { "/api/v1/template_properties/#{resource_id}" }

    describe 'GET' do
      subject { get(url, headers: headers) }
      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
      it_behaves_like 'a software_agent accessible resource'
    end

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
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
        let(:payload_key) { sibling_property.key }
        it_behaves_like 'a validated resource'
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'do
        let(:resource) { other_property }
      end
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
      end
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 204 }
      end

      context 'with associated meta_property' do
        include_context 'elasticsearch prep', [:resource], []
        before { FactoryGirl.create(:meta_property, property: resource) }
        it_behaves_like 'a validated resource'
      end
    end
  end
end
