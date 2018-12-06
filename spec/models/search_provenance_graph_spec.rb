require 'rails_helper'

RSpec.describe SearchProvenanceGraph do
  include_context 'mock all Uploads StorageProvider'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob
  let(:policy_scope) { Proc.new {|scope| scope } }

  # (activity)-(used)->(focus)
  let!(:focus) {
    FactoryBot.create(:file_version, label: "FOCUS")
  }

  let!(:activity) { FactoryBot.create(:activity, name: "ACTIVITY") }
  let!(:activity_creator) { activity.creator }
  let!(:activity_used_focus) {
    FactoryBot.create(:used_prov_relation,
      relatable_from: activity,
      relatable_to: focus
    )
  }

  # (activity)-(asocciatedWith)->(activity.creator)
  let!(:activity_associated_with_activity_creator) {
    FactoryBot.create(:associated_with_user_prov_relation,
      relatable_from: activity_creator,
      relatable_to: activity
    )
  }

  # (activity)-(associatedWith)->(software_agent)
  let!(:software_agent) {
    FactoryBot.create(:software_agent, name: "SOFTWARE_AGENT")
  }
  let!(:activity_associated_with_software_agent) {
    FactoryBot.create(:associated_with_software_agent_prov_relation,
      relatable_from: software_agent,
      relatable_to: activity
    )
  }

  # (focus)-(attributedTo)->(activity.creator)
  let!(:focus_attributed_to_activity_creator) {
    FactoryBot.create(:attributed_to_user_prov_relation,
      relatable_from: focus,
      relatable_to: activity_creator
    )
  }

  # (focus)-(attributedTo)->(software_agent)
  let!(:focus_attributed_to_software_agent) {
    FactoryBot.create(:attributed_to_software_agent_prov_relation,
      relatable_from: focus,
      relatable_to: software_agent
    )
  }

  # (generated_file)-(generatedBy)->(activity)
  let!(:generated_file) {
    FactoryBot.create(:file_version, label: "GENERATED_FILE")
  }
  let!(:generated_file_generated_by_activity) {
    FactoryBot.create(:generated_by_activity_prov_relation,
      relatable_from: generated_file,
      relatable_to: activity
    )
  }

  # (generated_file)-(derivedFrom)->(focus)
  let!(:generated_file_derived_from_focus) {
    FactoryBot.create(:derived_from_file_version_prov_relation,
      relatable_from: generated_file,
      relatable_to: focus
    )
  }

  # (generated_file)-(attributedTo)->(activity.creator)
  let!(:generated_file_attributed_to_activity_creator) {
    FactoryBot.create(:attributed_to_user_prov_relation,
      relatable_from: generated_file,
      relatable_to: activity.creator
    )
  }

  # (deleted_file)-(invalidatedBy)->(invalidating_activity)
  let(:deleted_file) {
    FactoryBot.create(:file_version, :deleted, label: "DELETED_FILE")
  }
  let!(:invalidating_activity) {
    FactoryBot.create(:activity, name: "INVALIDATING_ACTIVITY")
  }
  let!(:deleted_file_invalidated_by_invalidating_activity) {
    FactoryBot.create(:invalidated_by_activity_prov_relation,
      relatable_from: deleted_file,
      relatable_to: invalidating_activity
    )
  }

  # (deleted_file)-(derivedFrom)->(focus)
  let!(:deleted_file_derived_from_focus) {
    FactoryBot.create(:derived_from_file_version_prov_relation,
      relatable_from: deleted_file,
      relatable_to: focus
    )
  }

  # (invalidating_activity)-(asocciatedWith)->(activity_creator)
  let!(:invalidating_activity_associated_with_activity_creator) {
    FactoryBot.create(:associated_with_user_prov_relation,
      relatable_to: invalidating_activity,
      relatable_from: activity_creator
    )
  }

  # (invalidating_activity)-(associatedWith)->(other_software_agent)
  let!(:other_software_agent) {
    FactoryBot.create(:software_agent, name: "OTHER_SOFTWARE_AGENT")
  }
  let!(:invalidating_activity_associated_with_other_software_agent) {
    FactoryBot.create(:associated_with_software_agent_prov_relation,
      relatable_from: other_software_agent,
      relatable_to: invalidating_activity
    )
  }

  # (invalidating_activity)-(used)->(invalidating_file)
  let!(:invalidating_file) {
    FactoryBot.create(:file_version, label: "INVALIDATING_FILE")
  }
  let!(:invalidating_activity_used_invalidating_file) {
    FactoryBot.create(:used_prov_relation,
      relatable_to: invalidating_file,
      relatable_from: invalidating_activity
    )
  }

  # (deleted_file)-(attributedTo)->(activity.creator)
  let!(:deleted_file_attributed_to_activity_creator) {
    FactoryBot.create(:attributed_to_user_prov_relation,
      relatable_from: deleted_file,
      relatable_to: activity.creator
    )
  }

  it { expect(described_class).to include(ActiveModel::Serialization) }

  context 'initialization' do
    it {
      expect{
        described_class.new
      }.to raise_error(ArgumentError)
    }

    it {
      expect{
        described_class.new(focus: focus)
      }.to raise_error(ArgumentError)
    }

    it {
      expect {
        described_class.new(focus: focus, policy_scope: policy_scope)
      }.not_to raise_error
    }
  end

  context 'instantiations' do
    context 'default' do
      subject{
        SearchProvenanceGraph.new(
          focus: focus,
          policy_scope: policy_scope
        )
      }

      it_behaves_like 'A ProvenanceGraph', includes_node_syms: [
          :focus,
          # 1 hop
          :activity,
          :activity_creator,
          :software_agent,
          :generated_file,
          :deleted_file,
          # 2 hops
          :invalidating_activity,
          # 3 hops
          :invalidating_file,
          :other_software_agent
        ], includes_relationship_syms: [
          # 1 hop
          :activity_used_focus,
          :focus_attributed_to_activity_creator,
          :focus_attributed_to_software_agent,
          :generated_file_derived_from_focus,
          :deleted_file_derived_from_focus,
          # 2 hops
          :activity_associated_with_activity_creator,
          :activity_associated_with_software_agent,
          :generated_file_generated_by_activity,
          :generated_file_attributed_to_activity_creator,
          :deleted_file_invalidated_by_invalidating_activity,
          :deleted_file_attributed_to_activity_creator,
          # 3 hops
          :invalidating_activity_associated_with_activity_creator,
          :invalidating_activity_associated_with_other_software_agent,
          :invalidating_activity_used_invalidating_file
        ]
    end

    context 'max_hops 1' do
      subject{
        SearchProvenanceGraph.new(
          focus: focus,
          max_hops: 1,
          policy_scope: policy_scope
        )
      }

      it_behaves_like 'A ProvenanceGraph',
        includes_node_syms: [
          :focus,
          # 1 hop
          :activity,
          :activity_creator,
          :software_agent,
          :generated_file,
          :deleted_file
        ],
        excludes_node_syms: [
          # 2 hops
          :invalidating_activity,
          # 3 hops
          :invalidating_file,
          :other_software_agent
        ],
        includes_relationship_syms: [
          # 1 hop
          :activity_used_focus,
          :focus_attributed_to_activity_creator,
          :focus_attributed_to_software_agent,
          :generated_file_derived_from_focus,
          :deleted_file_derived_from_focus
        ],
        excludes_relationship_syms: [
          # 2 hops
          :activity_associated_with_activity_creator,
          :activity_associated_with_software_agent,
          :generated_file_generated_by_activity,
          :generated_file_attributed_to_activity_creator,
          :deleted_file_invalidated_by_invalidating_activity,
          :deleted_file_attributed_to_activity_creator,
          :invalidating_activity_associated_with_activity_creator,
          # 3 hops
          :invalidating_activity_associated_with_other_software_agent,
          :invalidating_activity_used_invalidating_file
        ]
    end

    context 'max_hops 2' do
      subject{
        SearchProvenanceGraph.new(
          focus: focus,
          max_hops: 2,
          policy_scope: policy_scope,
        )
      }

      it_behaves_like 'A ProvenanceGraph',
        includes_node_syms: [
          :focus,
          # 1 hop
          :activity,
          :activity_creator,
          :software_agent,
          :generated_file,
          :deleted_file,
          # 2 hops
          :invalidating_activity
        ],
        excludes_node_syms: [
          # 3 hops
          :invalidating_file,
          :other_software_agent
        ],
        includes_relationship_syms:[
          # 1 hop
          :activity_used_focus,
          :focus_attributed_to_activity_creator,
          :focus_attributed_to_software_agent,
          :generated_file_derived_from_focus,
          :deleted_file_derived_from_focus,
          # 2 hops
          :activity_associated_with_activity_creator,
          :activity_associated_with_software_agent,
          :generated_file_generated_by_activity,
          :generated_file_attributed_to_activity_creator,
          :deleted_file_invalidated_by_invalidating_activity,
          :deleted_file_attributed_to_activity_creator,
          :invalidating_activity_associated_with_activity_creator
        ],
        excludes_relationship_syms: [
          # 3 hops
          :invalidating_activity_associated_with_other_software_agent,
          :invalidating_activity_used_invalidating_file
        ]
    end

    context 'restrictive policy_scope' do
      subject{
        SearchProvenanceGraph.new(
          focus: focus,
          max_hops: 1,
          policy_scope: Proc.new { |scope| scope.none }
        )
      }

      it_behaves_like 'A ProvenanceGraph', with_restricted_properties: true,
        includes_node_syms: [
          :focus,
          # 1 hop
          :activity,
          :activity_creator,
          :software_agent,
          :generated_file,
          :deleted_file,
        ],
        excludes_node_syms: [
          # 2 hops
          :invalidating_activity,
          # 3 hops
          :invalidating_file,
          :other_software_agent
        ],
        includes_relationship_syms: [
          # 1 hop
          :activity_used_focus,
          :focus_attributed_to_activity_creator,
          :focus_attributed_to_software_agent,
          :generated_file_derived_from_focus,
          :deleted_file_derived_from_focus,
        ],
        excludes_relationship_syms: [
          # 2 hops
          :activity_associated_with_activity_creator,
          :activity_associated_with_software_agent,
          :generated_file_generated_by_activity,
          :generated_file_attributed_to_activity_creator,
          :deleted_file_invalidated_by_invalidating_activity,
          :deleted_file_attributed_to_activity_creator,
          # 3 hops
          :invalidating_activity_associated_with_activity_creator,
          :invalidating_activity_associated_with_other_software_agent,
          :invalidating_activity_used_invalidating_file
        ]
    end
  end
end
