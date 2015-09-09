require 'rails_helper'

describe DDS::V1::ProjectsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:deleted_project) { FactoryGirl.create(:project, :deleted) }
  let(:project_stub) { FactoryGirl.build(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }

  let(:resource_class) { Project }
  let(:resource_serializer) { ProjectSerializer }
  let!(:resource) { project }
  let!(:resource_permission) { project_permission }

  describe 'Project collection' do
    let(:url) { "/api/v1/projects" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      it_behaves_like 'a listable resource' do
        it 'should not include deleted projects' do
          expect(deleted_project).to be_persisted
          is_expected.to eq(200)
          expect(response.body).not_to include(resource_serializer.new(deleted_project).to_json)
        end
      end

      it_behaves_like 'an authenticated resource'
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:payload) {{
        name: resource.name,
        description: resource.description
      }}
      it_behaves_like 'a creatable resource' do
        let(:resource) { project_stub }
        it 'should set creator to current_user' do
          is_expected.to eq(201)
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('id')
          new_object = resource_class.find(response_json['id'])
          expect(new_object.creator_id).to eq(current_user.id)
        end
      end

      it_behaves_like 'an authenticated resource'

      it_behaves_like 'a validated resource' do
        let!(:payload) {{
          name: resource.name,
          description: nil
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end
    end
  end

  describe 'Project instance' do
    let(:url) { "/api/v1/projects/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:payload) {{
        name: project_stub.name,
        description: project_stub.description
      }}
      it_behaves_like 'an updatable resource'
      it_behaves_like 'a validated resource' do
        let(:payload) {{
            name: nil,
            description: nil,
        }}
      end

      it_behaves_like 'an authenticated resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }

        it 'should be marked as deleted' do
          expect(resource).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
        end
      end

      it_behaves_like 'an authenticated resource'
    end
  end
end
