require 'rails_helper'

describe DDS::V1::MetaTemplatesAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project) }
  let(:meta_template) { FactoryGirl.create(:meta_template, templatable: data_file) }
  let(:meta_template_stub) { FactoryGirl.build(:meta_template, templatable: data_file) }

  let(:template) { FactoryGirl.create(:template) }
  let(:property) { FactoryGirl.create(:property, template: template) }
  let(:meta_property_stub) { FactoryGirl.build(:meta_property, property: property) }

  let(:other_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user) }
  let(:other_data_file) { FactoryGirl.create(:data_file, project: other_permission.project) }
  let(:other_meta_template) { FactoryGirl.create(:meta_template, templatable: other_data_file) }

  let(:not_allowed_meta_template) { FactoryGirl.create(:meta_template) }

  let(:resource_class) { MetaTemplate }
  let(:resource_serializer) { MetaTemplateSerializer }
  let!(:resource) { meta_template }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }
  let(:resource_stub) { meta_template_stub }

  describe 'MetaTemplates collection' do
    let(:url) { "/api/v1/meta/#{resource_kind}/#{file_id}/#{template_id}" }
    let(:file_id) { data_file.id }
    let(:resource_kind) { data_file.kind }
    let(:template_id) { template.id }

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
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

      context 'with property key from another template' do
        let(:payload_property_key) { FactoryGirl.create(:property).key }
        it_behaves_like 'a validated resource'
      end

      context 'with blank property value' do
        let(:payload_property_value) { '' }
        it_behaves_like 'a validated resource'
      end
    end
  end
end
