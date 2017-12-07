require 'rails_helper'

describe DDS::V1::TagsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project) }
  let(:activity) { FactoryGirl.create(:activity, creator: current_user) }
  let(:taggable) { data_file }
  let(:tag) { FactoryGirl.create(:tag, taggable: taggable) }
  let(:tag_stub) { FactoryGirl.build(:tag, taggable: taggable) }

  let(:other_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user) }
  let(:other_taggable) { FactoryGirl.create(:data_file, project: other_permission.project) }
  let(:other_tag) { FactoryGirl.create(:tag, taggable: other_taggable) }

  let(:not_allowed_tag) { FactoryGirl.create(:tag) }

  let(:resource_class) { Tag }
  let(:resource_serializer) { TagSerializer }
  let!(:resource) { tag }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }
  let(:resource_stub) { tag_stub }

  describe 'Tags collection' do
    let(:url) { "/api/v1/tags/#{resource_kind}/#{taggable_id}" }
    let(:taggable_id) { taggable.id }
    let(:resource_kind) { taggable.kind }

    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      let!(:payload) {{
        label: payload_label
      }}
      let(:payload_label) { resource_stub.label }

      it_behaves_like 'a creatable resource' do
        it 'should set label' do
          is_expected.to eq(expected_response_status)
          expect(new_object.label).to eq(payload[:label])
        end
      end
      context 'with a taggable Activity' do
        let(:taggable) { activity }
        it_behaves_like 'a creatable resource'
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      it_behaves_like 'an identified resource' do
        let(:taggable_id) { 'notfoundid' }
        let(:resource_class) {'DataFile'}
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end

      context 'with blank label' do
        let(:payload_label) { '' }
        it_behaves_like 'a validated resource'
      end

      context 'with existing label' do
        let(:payload_label) { resource.label }
        it_behaves_like 'a validated resource'
      end
    end

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { expected_resources.length }
        let!(:expected_resources) { [
          tag
        ]}
        let!(:unexpected_resources) { [
          other_tag
        ] }
      end

      context 'with a taggable Activity' do
        let(:taggable) { activity }
        it_behaves_like 'a listable resource'
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with invalid taggable_id' do
        let(:taggable_id) { 'notfoundid' }
        let(:resource_class) { DataFile }
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end
    end
  end

  describe 'Append a list of object tags'  do
    let(:url) { "/api/v1/tags/#{resource_kind}/#{taggable_id}/append" }
    let(:taggable_id) { taggable.id }
    let(:resource_kind) { taggable.kind }
    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      let!(:payload) {{
        tags: [
          { label: payload_label },
          { label: payload_label },
          { label: payload_label },
          { label: payload_label }
        ]
      }}
      let(:payload_label) { resource_stub.label }

      def find_last_object_in_results
        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('results')
        expect(response_json['results']).to be_a(Array)
        expect(response_json['results']).not_to be_empty
        expect(response_json['results'].last).to have_key('id')
        resource_class.find(response_json['results'].last['id'])
      end

      it_behaves_like 'a creatable resource' do
        let(:new_object) { find_last_object_in_results }
        it 'should set label' do
          is_expected.to eq(expected_response_status)
          expect(new_object.label).to eq(payload_label)
        end
        it_behaves_like 'a listable resource' do
          let(:expected_response_status) { 201 }
          let(:expected_resources) { [new_object] }
          let(:serializable_resource) { new_object }
        end
      end
      context 'with a taggable Activity' do
        let(:taggable) { activity }
        it_behaves_like 'a creatable resource' do
          let(:new_object) { find_last_object_in_results }
        end
      end

      context 'with blank label' do
        let(:payload_label) { '' }
        it 'should not be persisted' do
          expect {
            is_expected.to eq(201)
          }.not_to change{resource_class.count}
        end
      end

      context 'with existing label' do
        let(:payload_label) { resource.label }
        it 'should not be persisted' do
          expect {
            is_expected.to eq(201)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      context 'with invalid taggable_id' do
        let(:taggable_id) { 'notfoundid' }
        let(:resource_class) { DataFile }
        it_behaves_like 'an identified resource'
      end

      context 'when object_kind unknown' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end
    end
  end

  describe 'Tag labels collection' do
    let(:url) { "/api/v1/tags/labels#{query_params}" }
    let(:query_params) { '' }
    let(:resource_class) { TagLabel }
    let(:resource_serializer) { TagLabelSerializer }
    let!(:resource_tag_label) { Tag.where(label: resource.label).tag_labels.first }
    let!(:not_allowed_tag_label) { Tag.where(label: not_allowed_tag.label).tag_labels.first }
    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { expected_resources.length }
        let!(:expected_resources) { [
          resource_tag_label
        ] }
        let(:serializable_resource) { expected_resources.first }
        let!(:unexpected_resources) { [
          not_allowed_tag_label
        ] }
      end
      context 'with a taggable Activity' do
        let(:taggable) { activity }
        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [ resource_tag_label ] }
          let(:serializable_resource) { expected_resources.first }
          let!(:unexpected_resources) { [ not_allowed_tag_label ] }
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with object_kind parameter' do
        let(:resource_kind) { resource.taggable.kind }
        let(:query_params) { "?object_kind=#{resource_kind}" }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            resource_tag_label
          ] }
          let(:serializable_resource) { expected_resources.first }
          let!(:unexpected_resources) { [
            not_allowed_tag_label
          ] }
        end

        context 'when object_kind unknown' do
          let(:resource_kind) { 'invalid-kind' }
          it_behaves_like 'a kinded resource'
        end
      end

      context 'with label_contains parameter' do
        let(:label_query) { SecureRandom.hex }
        let!(:resource) { FactoryGirl.create(:tag, label: "what #{label_query} ever", taggable: taggable) }
        let!(:diff_tag) { FactoryGirl.create(:tag, taggable: taggable) }
        let!(:diff_tag_label) { Tag.where(label: diff_tag.label).tag_labels.first }
        let(:query_params) { "?label_contains=#{label_query}" }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            resource_tag_label
          ]}
          let(:serializable_resource) { expected_resources.first }
          let!(:unexpected_resources) { [
            diff_tag_label,
            not_allowed_tag_label
          ] }
        end
      end
    end
  end

  describe 'Tag instance' do
    let(:url) { "/api/v1/tags/#{resource_id}" }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'
      context 'with a taggable Activity' do
        let(:taggable) { activity }
        it_behaves_like 'a viewable resource'
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource'
      context 'with a taggable Activity' do
        let(:taggable) { activity }
        it_behaves_like 'a removable resource'
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) {204}
      end
      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end
  end
end
