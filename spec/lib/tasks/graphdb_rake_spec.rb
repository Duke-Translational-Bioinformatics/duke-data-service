require 'rails_helper'

describe "graphdb", :if => ENV['TEST_RAKE_GRAPHDB'] do
  let(:current_user) { FactoryGirl.create(:user) }
  def annotate_audit(audit, audited_software_agent=nil)
    comment_annotation = {
      endpoint: "/graphdb",
      action: 'build'
    }
    if audited_software_agent
      comment_annotation['software_agent_id'] = audited_software_agent.id
    end

    audit_update = {
      request_uuid: SecureRandom.hex,
      remote_address: '10.10.10.10',
      comment: audit.comment ?
        audit.comment.merge(comment_annotation) :
        comment_annotation
    }
    audit.update(audit_update)
  end

  before(:all) do
    Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    AssociatedWithUserProvRelation.destroy_all
    AssociatedWithSoftwareAgentProvRelation.destroy_all
    AttributedToUserProvRelation.destroy_all
    AttributedToSoftwareAgentProvRelation.destroy_all
    User.destroy_all
    SoftwareAgent.destroy_all
    Activity.destroy_all
    FileVersion.destroy_all
    Upload.destroy_all
    DataFile.destroy_all
    Audited.audit_class.destroy_all

    #these simulate objects with ProvRelations that need nodes and relationsips
    FactoryGirl.create_list(:user, 1).each do |user|
      Audited.audit_class.as_user(user) do
        sa = FactoryGirl.create(:software_agent, creator: user)
        annotate_audit(sa.audits.last)
        user_upload = FactoryGirl.create(:upload, :completed, :with_fingerprint, creator: user)
        annotate_audit(user_upload.audits.last)

        user_df = FactoryGirl.create(:data_file, upload: user_upload)
        annotate_audit(user_df.audits.last)

        user_fv = FactoryGirl.create(:file_version, data_file: user_df)
        annotate_audit(user_fv.audits.last)
        a2u = AttributedToUserProvRelation.create(
          creator: user,
          relatable_from: user_fv,
          relatable_to: user)
        annotate_audit(a2u.audits.last)

        user_activity = FactoryGirl.create(:activity, creator: user)
        annotate_audit(user_activity.audits.last)

        aWu = AssociatedWithUserProvRelation.create(
          creator: user,
          relatable_from: user,
          relatable_to: user_activity)
        annotate_audit(aWu.audits.last)

        sa_upload = FactoryGirl.create(:upload, :completed, :with_fingerprint, creator: user)
        annotate_audit(sa_upload.audits.last, sa)

        sa_df = FactoryGirl.create(:data_file, upload: sa_upload)
        annotate_audit(sa_df.audits.last, sa)

        sa_fv = FactoryGirl.create(:file_version, data_file: sa_df)
        annotate_audit(sa_fv.audits.last, sa)

        a2u2 = AttributedToUserProvRelation.create(
          creator: user,
          relatable_from: sa_fv,
          relatable_to: user)
        annotate_audit(a2u2.audits.last, sa)

        a2sa = AttributedToSoftwareAgentProvRelation.create(
          creator: user,
          relatable_from: sa_fv,
          relatable_to: sa)
        annotate_audit(a2sa.audits.last, sa)

        sa_activity = FactoryGirl.create(:activity, creator: user)
        annotate_audit(sa_activity.audits.last, sa)
        aWu2 = AssociatedWithUserProvRelation.create(
          creator: user,
          relatable_from: user,
          relatable_to: sa_activity)
        annotate_audit(aWu2.audits.last, sa)
        aWsa = AssociatedWithSoftwareAgentProvRelation.create(
          creator: user,
          relatable_from: sa,
          relatable_to: sa_activity)
        annotate_audit(aWsa.audits.last, sa)
      end
    end

    #these simulate objects that need ProvRelations as well as nodes
    # and relationships
    FactoryGirl.create_list(:user, 1).each do |user|
      Audited.audit_class.as_user(user) do
        sa = FactoryGirl.create(:software_agent, creator: user)
        annotate_audit(sa.audits.last)
        user_upload = FactoryGirl.create(:upload, :completed, :with_fingerprint, creator: user)
        annotate_audit(user_upload.audits.last)

        user_df = FactoryGirl.create(:data_file, upload: user_upload)
        annotate_audit(user_df.audits.last)

        user_fv = FactoryGirl.create(:file_version, data_file: user_df)
        annotate_audit(user_fv.audits.last)

        user_activity = FactoryGirl.create(:activity, creator: user)
        annotate_audit(user_activity.audits.last)

        sa_upload = FactoryGirl.create(:upload, :completed, :with_fingerprint, creator: user)
        annotate_audit(sa_upload.audits.last, sa)

        sa_df = FactoryGirl.create(:data_file, upload: sa_upload)
        annotate_audit(sa_df.audits.last, sa)

        sa_fv = FactoryGirl.create(:file_version, data_file: sa_df)
        annotate_audit(sa_fv.audits.last, sa)

        sa_activity = FactoryGirl.create(:activity, creator: user)
        annotate_audit(sa_activity.audits.last, sa)
      end
    end
  end

  describe "graphdb:build" do
    include_context "rake"
    let(:task_name) { "graphdb:build" }
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }
    it { expect(subject.prerequisites).to  include("environment") }

    before do
      Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    end

    it 'should build all graph_nodes, prov_relations, and graph_relations' do
      invoke_task
      User.all.each do |user|
        expect(user.graph_node).to be
      end

      SoftwareAgent.all.each do |sa|
        expect(sa.graph_node).to be
      end

      Activity.all.each do |activity|
        expect(activity.graph_node).to be
        creation_audit = activity.audits.where(action: 'create').take
        associated_with_user = AssociatedWithUserProvRelation.where(
          relatable_from: creation_audit.user, relatable_to: activity
        ).take
        expect(associated_with_user).to be
        expect(associated_with_user.graph_relation).to be
        if creation_audit.comment && creation_audit.comment.has_key?( "software_agent_id" )
          sa = SoftwareAgent.find(creation_audit.comment["software_agent_id"])
          associated_with_software_agent = AssociatedWithSoftwareAgentProvRelation.where(
            relatable_from: sa, relatable_to: activity
          ).take
          expect(associated_with_software_agent).to be
          expect(associated_with_software_agent.graph_relation).to be
        end
      end

      FileVersion.all.each do |file_version|
        expect(file_version.graph_node).to be
        creation_audit = file_version.audits.where(action: 'create').take
        attributed_to_user = AttributedToUserProvRelation.where(
          relatable_to: creation_audit.user, relatable_from: file_version
        ).take
        expect(attributed_to_user).to be
        expect(attributed_to_user.graph_relation).to be
        if creation_audit.comment && creation_audit.comment.has_key?( "software_agent_id" )
          sa = SoftwareAgent.find(creation_audit.comment["software_agent_id"])
          attributed_to_software_agent = AttributedToSoftwareAgentProvRelation.where(
            relatable_to: sa, relatable_from: file_version
          ).take
          expect(attributed_to_software_agent).to be
          expect(attributed_to_software_agent.graph_relation).to be
        end
      end
    end
  end

  describe 'graphdb:clean' do
    include_context "rake"
    let(:task_name) { "graphdb:clean" }
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }
    it { expect(subject.prerequisites).to  include("environment") }

    it 'should remove all graph nodes and relationships' do
      invoke_task
      expect(
        Neo4j::Session.query.match('n').pluck(:n).count
      ).to eq(0)
      expect(
        Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() RETURN r').count
      ).to eq(0)
    end
  end
end
