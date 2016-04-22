require 'rails_helper'

describe DDS::V1::TagsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project) }
  let(:tag) { FactoryGirl.create(:tag, taggable: data_file) }
  let(:tag_stub) { FactoryGirl.build(:tag, taggable: data_file) }

  let(:other_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user) }
  let(:other_data_file) { FactoryGirl.create(:data_file, project: other_permission.project) }
  let(:other_tag) { FactoryGirl.create(:tag, taggable: other_data_file) }

  let(:resource_class) { Tag }
  let(:resource_serializer) { TagSerializer }
  let!(:resource) { tag }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }
  let(:resource_stub) { tag_stub }

  describe 'Tags collection' do
    let(:url) { "/api/v1/tags" }

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }
      let(:taggable_object) {{ kind: data_file.kind, id: data_file.id }}
      let!(:payload) {{
        object: taggable_object,
        label: resource_stub.label
      }}

      it_behaves_like 'a creatable resource' do
        it 'should set label' do
          is_expected.to eq(expected_response_status)
          expect(new_object.label).to eq(payload[:label])
        end
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      it_behaves_like 'an identified resource' do
        let(:taggable_object) {{ kind: data_file.kind, id: 'notfoundid' }}
        let(:resource_class) {'DataFile'}
      end
    end
  end

  describe 'Tag collection for object'  do
    let(:url) { "/api/v1/tags/#{data_file.kind}/#{file_id}" }
    let(:file_id) { data_file.id }
    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { expected_resources.length }
        let!(:expected_resources) { [
          tag
        ]}
        let!(:unexpected_resources) { [
          other_tag
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with invalid file_id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) { DataFile }
        it_behaves_like 'an identified resource'
      end
    end
  end

  describe 'Tag instance' do
    let(:url) { "/api/v1/tags/#{resource_id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end
  end

end
