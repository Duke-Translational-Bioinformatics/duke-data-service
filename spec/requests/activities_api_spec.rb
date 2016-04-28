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
      subject { get(url, nil, headers) }
      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          deleted_activity
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
    end #GET

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { "POST" }
      let(:payload) {{
        name: resource_stub.name,
        description: resource_stub.description,
        started_on: resource_stub.started_on,
        ended_on: resource_stub.ended_on
      }}
      it_behaves_like 'a creatable resource' do
        let(:resource) { resource_stub }
        it 'should set creator to current_user and create an agent_activity_association' do
          expect {
            is_expected.to eq(201)
          }.to change{ AgentActivityAssociation.count }.by(1)
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('id')
          new_object = resource_class.find(response_json['id'])
          expect(new_object.creator_id).to eq(current_user.id)
          expect(AgentActivityAssociation.where(agent_id: current_user.id, activity_id: new_object.id).first).to be
        end
      end

      it_behaves_like 'an authenticated resource'

      it_behaves_like 'a software_agent accessible resource' do
        let(:resource) { activity_stub }
        let(:expected_response_status) { 201 }
        it_behaves_like 'an annotate_audits endpoint' do
          let(:resource) { activity_stub }
          let(:expected_response_status) { 201 }
        end

        it_behaves_like 'an annotate_audits endpoint' do
          let(:resource) { activity_stub }
          let(:expected_auditable_type) { AgentActivityAssociation }
          let(:expected_response_status) { 201 }
          let(:expected_audits) { 2 }
        end

        it 'should create two agent_activity_associations' do
          expect {
            is_expected.to eq(201)
          }.to change{ AgentActivityAssociation.count }.by(2)
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('id')
          new_object = resource_class.find(response_json['id'])
          expect(AgentActivityAssociation.where(agent_id: current_user.id, activity_id: new_object.id).first).to be
          expect(AgentActivityAssociation.where(agent_id: software_agent.id, activity_id: new_object.id).first).to be
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

      it_behaves_like 'an annotate_audits endpoint' do
        let(:resource) { activity_stub }
        let(:expected_auditable_type) { AgentActivityAssociation }
        let(:expected_response_status) { 201 }
      end
    end #POST
  end #Activities collection

  describe 'Activities instance' do
    let(:url) { "/api/v1/activities/#{resource.id}" }
    describe 'GET' do
      subject { get(url, nil, headers) }
      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let(:payload) {{
        name: resource_stub.name,
        description: resource_stub.description,
        started_on: resource_stub.started_on,
        ended_on: resource_stub.ended_on
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'a validated resource' do
        let(:payload) {{
            name: nil
        }}
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint'
      it_behaves_like 'a logically deleted resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }
        let(:agent_activity_association) { FactoryGirl.create(:user_activity_association, agent: current_user, activity_id: resource.id) }

        it 'should be marked as deleted and not delete agent_activity_association' do
          expect(resource).to be_persisted
          expect(agent_activity_association).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
          agent_activity_association.reload
          expect(agent_activity_association).to be_persisted
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
        let(:agent_activity_association) { FactoryGirl.create(:user_activity_association, agent: current_user, activity_id: resource.id) }
        let(:software_agent_activity_association) { FactoryGirl.create(:software_agent_activity_association, agent: software_agent, activity_id: resource.id) }
        it 'should not delete any agent_activity_associations' do
          expect(resource).to be_persisted
          expect(agent_activity_association).to be_persisted
          expect(software_agent_activity_association).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
          agent_activity_association.reload
          expect(agent_activity_association).to be_persisted
          software_agent_activity_association.reload
          expect(software_agent_activity_association).to be_persisted
        end
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 204 }
        end
      end
    end
  end #Activities instance
end
