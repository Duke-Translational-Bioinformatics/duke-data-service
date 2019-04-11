require 'rails_helper'

describe "graphdb" do
  let(:current_user) { FactoryBot.create(:user) }

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
    FactoryBot.create_list(:user, 2).each do |user|
      sa = FactoryBot.create(:software_agent, creator: user)
      user_upload = FactoryBot.create(:upload, :completed, :with_fingerprint, creator: user)
      user_df = FactoryBot.create(:data_file, upload: user_upload)
      user_fv = FactoryBot.create(:file_version, data_file: user_df)
      AttributedToUserProvRelation.create(
        creator: user,
        relatable_from: user_fv,
        relatable_to: user)
      user_activity = FactoryBot.create(:activity, creator: user)
      AssociatedWithUserProvRelation.create(
        creator: user,
        relatable_from: user,
        relatable_to: user_activity)
      sa_upload = FactoryBot.create(:upload, :completed, :with_fingerprint, creator: user)
      sa_df = FactoryBot.create(:data_file, upload: sa_upload)
      sa_fv = FactoryBot.create(:file_version, data_file: sa_df)
      AttributedToUserProvRelation.create(
        creator: user,
        relatable_from: sa_fv,
        relatable_to: user)
      AttributedToSoftwareAgentProvRelation.create(
        creator: user,
        relatable_from: sa_fv,
        relatable_to: sa)
      sa_activity = FactoryBot.create(:activity, creator: user)
      AssociatedWithUserProvRelation.create(
        creator: user,
        relatable_from: user,
        relatable_to: sa_activity)
      AssociatedWithSoftwareAgentProvRelation.create(
        creator: user,
        relatable_from: sa,
        relatable_to: sa_activity)
    end
  end

  describe "graphdb:build" do
    include_context "rake"
    let(:task_name) { "graphdb:build" }
    it { expect(subject.prerequisites).to  include("environment") }

    before do
      Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    end

    it 'should build all graph_nodes, prov_relations, and graph_relations' do
      invoke_task
      User.all.each do |user|
        expect(user.graph_node).not_to be_nil
      end

      SoftwareAgent.all.each do |sa|
        expect(sa.graph_node).not_to be_nil
      end

      FileVersion.all.each do |file_version|
        expect(file_version.graph_node).not_to be_nil
      end

      Activity.all.each do |activity|
        expect(activity.graph_node).not_to be_nil
      end
    end
  end

  describe 'graphdb:clean' do
    include_context "rake"
    let(:task_name) { "graphdb:clean" }
    it { expect(subject.prerequisites).to  include("environment") }

    it 'should remove all graph nodes and relationships' do
      invoke_task
      expect(
        Neo4j::Session.query.match('(n)').pluck(:n).count
      ).to eq(0)
      expect(
        Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() RETURN r').count
      ).to eq(0)
    end
  end
end
