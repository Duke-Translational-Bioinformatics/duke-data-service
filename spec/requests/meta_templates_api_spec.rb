require 'rails_helper'

describe DDS::V1::MetaTemplatesAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project) }
  let(:meta_template) { FactoryGirl.create(:meta_template, templatable: data_file) }
  let(:meta_template_stub) { FactoryGirl.build(:meta_template, templatable: data_file) }

  let(:template) { meta_template.template }
  let(:property_data_type) { 'string' }
  let(:property) { FactoryGirl.create(:property, data_type: property_data_type, template: template) }
  let(:meta_property) { FactoryGirl.create(:meta_property, property: property, meta_template: meta_template) }
  let(:meta_property_stub) { FactoryGirl.build(:meta_property, property: property) }

  let(:other_permission) { FactoryGirl.create(:project_permission, :project_admin) }
  let(:other_data_file) { FactoryGirl.create(:data_file, project: other_permission.project) }
  let(:other_meta_template) { FactoryGirl.create(:meta_template, templatable: other_data_file) }

  let(:not_allowed_meta_template) { FactoryGirl.create(:meta_template) }

  let(:resource_class) { MetaTemplate }
  let(:resource_serializer) { MetaTemplateSerializer }
  let!(:resource) { meta_template }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }
  let(:resource_stub) { meta_template_stub }

  let(:file_id) { data_file.id }
  let(:resource_kind) { data_file.kind }

  describe 'MetaTemplates collection' do
    let(:url) { "/api/v1/meta/#{resource_kind}/#{file_id}" }

    describe 'GET' do
      subject { get(url, params: query_params, headers: headers) }
      let(:query_params) {{}}
      let(:different_data_file) { FactoryGirl.create(:data_file, project: project) }
      let(:meta_template_diff_file) { FactoryGirl.create(:meta_template, templatable: different_data_file) }
      let(:meta_template_diff_template) { FactoryGirl.create(:meta_template, templatable: data_file) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { expected_resources.length }
        let!(:expected_resources) { [
          resource,
          meta_template_diff_template
        ]}
        let!(:unexpected_resources) { [
          other_meta_template,
          meta_template_diff_file
        ] }
      end
      context 'with meta_template_name parameter' do
        let(:query_params) {{meta_template_name: resource.template.name}}
        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            resource
          ]}
          let!(:unexpected_resources) { [
            other_meta_template,
            meta_template_diff_file,
            meta_template_diff_template
          ] }
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with a nonexistent file id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) {'DataFile'}
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end
    end
  end

  describe 'Object Metadata Instance' do
    let(:url) { "/api/v1/meta/#{resource_kind}/#{file_id}/#{template_id}" }
    let(:template_id) { template.id }

    describe 'POST' do
      include_context 'elasticsearch prep', [:template, :property], [:data_file]

      subject { post(url, params: payload.to_json, headers: headers) }
      let(:template) { FactoryGirl.create(:template) }
      let(:called_action) { 'POST' }
      let!(:payload) {{
        properties: [
          {
            "key": payload_property_key,
            "value": payload_property_value
          }
        ]
      }}
      let(:payload_property_key) { property.key }
      let(:payload_property_value) { meta_property_stub.value }

      it_behaves_like 'a creatable resource' do
        let(:new_object) { MetaTemplate.where(template: template, templatable_id: file_id).first }
        it 'should create a property' do
          expect{
            is_expected.to eq(expected_response_status)
          }.to change{MetaProperty.count}.by(1)
        end
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      context 'with a nonexistent file id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) {'DataFile'}
        it_behaves_like 'an identified resource'
      end

      context 'with a nonexistent template id' do
        let(:template_id) { 'notfoundid' }
        let(:resource_class) {'Template'}
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end

      context 'with blank property key' do
        let(:payload_property_key) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'with invalid numeric value' do
        let(:property_data_type) { 'integer' }
        it_behaves_like 'a validated resource'
      end

      context 'with invalid date value' do
        let(:property_data_type) { 'date' }
        it_behaves_like 'a validated resource'
      end

      context 'with property key from another template' do
        let(:payload_property_key) { FactoryGirl.create(:property).key }
        it_behaves_like 'a validated resource'
      end

      context 'with blank property value' do
        let(:payload_property_value) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'when template exists' do
        let(:template) { resource.template }
        let(:response_json) { JSON.parse(response.body) }
        it 'returns a unique conflict' do
          is_expected.to eq(409)
          expect(response_json).to include({
            'error' => '409',
            'reason' => 'unique conflict',
            'suggestion' => 'Resubmit as an update request'
          })
        end
      end
    end

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with a nonexistent file id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) {'DataFile'}
        it_behaves_like 'an identified resource'
      end

      context 'with a nonexistent template id' do
        let(:template_id) { 'notfoundid' }
        let(:resource_class) {'Template'}
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end

      context 'with a nonexistent meta template' do
        let(:template) { FactoryGirl.create(:template) }
        let(:resource_class) {'MetaTemplate'}
        it_behaves_like 'an identified resource'
      end
    end

    describe 'PUT' do
      include_context 'elasticsearch prep', [:template, :property], [:data_file]

      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        properties: [
          {
            "key": payload_property_key,
            "value": payload_property_value
          }
        ]
      }}
      let(:payload_property_key) { property.key }
      let(:payload_property_value) { meta_property_stub.value }

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with existing meta property key' do
        let(:payload_property_key) { meta_property.property.key }
        it_behaves_like 'an updatable resource' do
          it 'should not create a new meta property' do
            expect {
              is_expected.to eq(expected_response_status)
            }.not_to change{MetaProperty.count}
          end
        end
      end

      context 'with a nonexistent file id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) {'DataFile'}
        it_behaves_like 'an identified resource'
      end

      context 'with a nonexistent template id' do
        let(:template_id) { 'notfoundid' }
        let(:resource_class) {'Template'}
        it_behaves_like 'an identified resource'
      end

      context 'with a nonexistent meta template' do
        let(:template) { FactoryGirl.create(:template) }
        let(:resource_class) {'MetaTemplate'}
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end

      context 'with blank property key' do
        let(:payload_property_key) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'with property key from another template' do
        let(:payload_property_key) { FactoryGirl.create(:property).key }
        it_behaves_like 'a validated resource'
      end

      context 'with blank property value' do
        let(:payload_property_value) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'with invalid numeric value' do
        let(:property_data_type) { 'integer' }
        it_behaves_like 'a validated resource'
      end

      context 'with invalid date value' do
        let(:property_data_type) { 'date' }
        it_behaves_like 'a validated resource'
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }

      it_behaves_like 'a removable resource'
      context 'with associated meta_property' do
        include_context 'elasticsearch prep', [:template, :property], [:data_file]
        before { expect(meta_property).to be_persisted }
        it 'should destroy meta_property' do
          expect {
            is_expected.to eq 204
          }.to change{MetaProperty.count}.by(-1)
        end
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) {204}
      end

      context 'with a nonexistent file id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) {'DataFile'}
        it_behaves_like 'an identified resource'
      end

      context 'with a nonexistent template id' do
        let(:template_id) { 'notfoundid' }
        let(:resource_class) {'Template'}
        it_behaves_like 'an identified resource'
      end

      context 'with a nonexistent meta template' do
        let(:template) { FactoryGirl.create(:template) }
        let(:resource_class) {'MetaTemplate'}
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end
    end
  end
end
