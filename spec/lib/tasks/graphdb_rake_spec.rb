require 'rails_helper'

describe "graphdb" do
  include_context "rake"
  let(:task_path) { "lib/tasks/graphdb" }
  let(:current_user) { FactoryGirl.create(:user) }

  it { expect(subject.prerequisites).to  include("environment") }

  def annotate_audit(audit, audited_software_agent=nil)
    comment_annotation = {
      endpoint: "/graphdb"
      action: 'build'
    }
    if audited_software_agent
      comment_annotation['software_agent_id'] = audited_software_agent.id
    end

    audit_update = {
      request_uuid: SecureRandom.hex,
      remote_address: '10.10.10.10'
    }
    audit_update[:comment] = audit.comment ?
      audit.comment.merge(comment_annotation) :
      comment_annotation
    audit.update(audit_update)
  end

  before do
    FactoryGirl.create_list(:user, 2).each do |user|
      Audited.audit_class.as_user(user) do
        sa FactoryGirl.create(:software_agent, creator: user)
        annotate_audit(sa.audits.last)
        user_upload = FactoryGirl.create(:upload, creator: user)
        annotate_audit(user_upload.audits.last)

        user_df = FactoryGirl.create(:data_file, upload: user_upload)
        annotate_audit(user_df.audits.last)

        user_fv = FactoryGirl.create(:file_version, data_file: user_df)
        annotate_audit(user_fv.audits.last)

        a2u = AttributedToUserProvRelation.create(
          creator: user,
          relatable_from: user_fv,
          relationship_type: 'was-attributed-to',
          relatable_to: user)
        annotate_audit(a2u.audits.last)

        user_activity = FactoryGirl.create(:activity, creator: user)
        annotate_audit(user_activity.audits.last)

        aWu = AssociatedWithUserProvRelation.create(
          creator: user,
          relatable_from: user,
          relationship_type: 'was-associated-with',
          relatable_to: user_activity)
        annotate_audit(aWu.audits.last)

        sa_upload = FactoryGirl.create(:upload, creator: user)
        annotate_audit(sa_upload.audits.last, sa)

        sa_df = FactoryGirl.create(:data_file, upload: sa_upload)
        annotate_audit(sa_df.audits.last, sa)

        sa_fv = FactoryGirl.create(:file_version, data_file: sa_df)
        annotate_audit(sa_fv.audits.last, sa)

        a2u2 = AttributedToUserProvRelation.create(
          creator: user,
          relatable_from: sa_fv,
          relationship_type: 'was-attributed-to',
          relatable_to: user)
        annotate_audit(a2u2.audits.last, sa)

        a2sa= AttributedToSoftwareAgentProvRelation.create(
          creator: user,
          relatable_from: sa_fv,
          relationship_type: 'was-attributed-to',
          relatable_to: sa)
        annotate_audit(a2sa.audits.last, sa)

        sa_activity = FactoryGirl.create(:activity, creator: user)
        annotate_audit(sa_activity.audits.last, sa)
        aWu2 = AssociatedWithUserProvRelation.create(
          creator: user,
          relatable_from: user,
          relationship_type: 'was-associated-with',
          relatable_to: sa_activity)
        annotate_audit(aWu2.audits.last, sa)
        aWsa = AssociatedWithSoftwareAgentProvRelation.create(
          creator: user,
          relatable_from: sa,
          relationship_type: 'was-associated-with',
          relatable_to: sa_activity)
        annotate_audit(aWsa.audits.last, sa)
      end
    end
  end

  describe ":build" do
    let(:task_name) { 'graphdb:build' }
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }

    it 'should build all graph_nodes and relationships' do
      Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
      invoke_task
      #there should be nodes and relationships
    end
  end

  describe ':clean' do
    let(:task_name) { 'graphdb:clean' }
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }

    it 'should remove all graph nodes and relationships' do
      invoke_task
      expect(
        Neo4j::Session.query('MATCH (n) RETURN n').pluck(:n).count
      ).to eq(0)
      expect(
        Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() RETURN r').pluck(:r).count
      ).to eq(0)
    end
  end
end
