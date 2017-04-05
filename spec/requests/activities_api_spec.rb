require 'rails_helper'

describe DDS::V1::ActivitiesAPI do
  include_context 'with authentication'

  let(:activity) { FactoryGirl.create(:activity) }
  let(:activity_stub) { FactoryGirl.build(:activity) }
  let(:system_permission) { FactoryGirl.create(:system_permission, user: current_user) }
  let(:deleted_activity) { FactoryGirl.create(:activity, :deleted) }
  let(:resource_class) { Activity }
  let(:resource_serializer) { ActivitySerializer }
  let!(:resource) { activity }
  let(:resource_stub) { activity_stub }
  let!(:resource_permission) { system_permission }

  describe 'Activities collection' do
    let(:url) { "/api/v1/activities" }
    describe 'GET' do
      subject { get(url, headers: headers) }
      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          deleted_activity
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
    end #GET

    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { "POST" }
      let(:payload) {{
        name: resource_stub.name,
        description: resource_stub.description,
        started_on: resource_stub.started_on,
        ended_on: resource_stub.ended_on
      }}
      it_behaves_like 'a creatable resource' do
        let(:resource) { resource_stub }
        it 'should set creator to current_user' do
            is_expected.to eq(201)
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('id')
          new_object = resource_class.find(response_json['id'])
          expect(new_object.creator_id).to eq(current_user.id)
        end
      end

      it_behaves_like 'an authenticated resource'

      it_behaves_like 'a software_agent accessible resource' do
        let(:resource) { activity_stub }
        let(:expected_response_status) { 201 }

        context 'Activity Audit' do
          it_behaves_like 'an annotate_audits endpoint' do
            let(:resource) { activity_stub }
            let(:expected_response_status) { 201 }
          end
        end

        context 'ProvRelations' do
          it 'should be created' do
            is_expected.to eq(201)
            response_json = JSON.parse(response.body)
            expect(response_json).to have_key('id')
            new_object = resource_class.find(response_json['id'])
          end
        end
      end

      it_behaves_like 'a validated resource' do
        let!(:payload) {{
          name: nil
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:resource) { activity_stub }
        let(:expected_response_status) { 201 }
      end
    end #POST
  end #Activities collection

  describe 'Activities instance' do
    let(:url) { "/api/v1/activities/#{resource_id}" }
    let(:resource_id) { resource.id }

    describe 'GET' do
      subject { get(url, headers: headers) }
      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let(:payload) {{
        name: resource_stub.name,
        description: resource_stub.description,
        started_on: resource_stub.started_on,
        ended_on: resource_stub.ended_on
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint'
      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }
        let(:associated_with_user_prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation, relatable_from: current_user, relatable_to: resource) }

        it 'should be marked as deleted and not delete associated_with_user_prov_relation' do
          expect(resource).to be_persisted
          expect(associated_with_user_prov_relation).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
          associated_with_user_prov_relation.reload
          expect(associated_with_user_prov_relation).to be_persisted
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
      end
      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 204 }
        let(:associated_with_user_prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation, relatable_from: current_user, relatable_to: resource) }
        let(:associated_with_software_agent_prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation, relatable_from: software_agent, relatable_to: resource) }
        it 'should not delete any associated_with prov_relations' do
          expect(resource).to be_persisted
          expect(associated_with_user_prov_relation).to be_persisted
          expect(associated_with_software_agent_prov_relation).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
          associated_with_user_prov_relation.reload
          expect(associated_with_user_prov_relation).to be_persisted
          associated_with_software_agent_prov_relation.reload
          expect(associated_with_software_agent_prov_relation).to be_persisted
        end
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 204 }
        end
      end
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end
  end #Activities instance
end
