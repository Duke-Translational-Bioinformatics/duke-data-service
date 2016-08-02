require 'rails_helper'

RSpec.describe ProvenanceGraph do
  let(:policy_scope) { Proc.new {|scope| scope } }

  # (activity)-(used)->(focus)
  let!(:focus) {
    FactoryGirl.create(:file_version, label: "FOCUS")
  }

  let!(:activity) { FactoryGirl.create(:activity, name: "ACTIVITY") }
  let!(:activity_creator) { activity.creator }
  let!(:activity_used_focus) {
    FactoryGirl.create(:used_prov_relation,
      relatable_from: activity,
      relatable_to: focus
    )
  }

  # (activity)-(asocciatedWith)->(activity.creator)
  let!(:activity_associated_with_activity_creator) {
    FactoryGirl.create(:associated_with_user_prov_relation,
      relatable_from: activity_creator,
      relatable_to: activity
    )
  }

  # (activity)-(associatedWith)->(software_agent)
  let!(:software_agent) {
    FactoryGirl.create(:software_agent, name: "SOFTWARE_AGENT")
  }
  let!(:activity_associated_with_software_agent) {
    FactoryGirl.create(:associated_with_software_agent_prov_relation,
      relatable_from: software_agent,
      relatable_to: activity
    )
  }

  # (focus)-(attributedTo)->(activity.creator)
  let!(:focus_attributed_to_activity_creator) {
    FactoryGirl.create(:attributed_to_user_prov_relation,
      relatable_from: focus,
      relatable_to: activity_creator
    )
  }

  # (focus)-(attributedTo)->(software_agent)
  let!(:focus_attributed_to_software_agent) {
    FactoryGirl.create(:attributed_to_software_agent_prov_relation,
      relatable_from: focus,
      relatable_to: software_agent
    )
  }

  # (generated_file)-(generatedBy)->(activity)
  let!(:generated_file) {
    FactoryGirl.create(:file_version, label: "GENERATED_FILE")
  }
  let!(:generated_file_generated_by_activity) {
    FactoryGirl.create(:generated_by_activity_prov_relation,
      relatable_from: generated_file,
      relatable_to: activity
    )
  }

  # (generated_file)-(derivedFrom)->(focus)
  let!(:generated_file_derived_from_focus) {
    FactoryGirl.create(:derived_from_file_version_prov_relation,
      relatable_from: generated_file,
      relatable_to: focus
    )
  }

  # (generated_file)-(attributedTo)->(activity.creator)
  let!(:generated_file_attributed_to_activity_creator) {
    FactoryGirl.create(:attributed_to_user_prov_relation,
      relatable_from: generated_file,
      relatable_to: activity.creator
    )
  }

  # (deleted_file)-(invalidatedBy)->(invalidating_activity)
  let(:deleted_file) {
    FactoryGirl.create(:file_version, :deleted, label: "DELETED_FILE")
  }
  let!(:invalidating_activity) {
    FactoryGirl.create(:activity, name: "INVALIDATING_ACTIVITY")
  }
  let!(:deleted_file_invalidated_by_invalidating_activity) {
    FactoryGirl.create(:invalidated_by_activity_prov_relation,
      relatable_from: deleted_file,
      relatable_to: invalidating_activity
    )
  }

  # (deleted_file)-(derivedFrom)->(focus)
  let!(:deleted_file_derived_from_focus) {
    FactoryGirl.create(:derived_from_file_version_prov_relation,
      relatable_from: deleted_file,
      relatable_to: focus
    )
  }

  # (invalidating_activity)-(asocciatedWith)->(activity_creator)
  let!(:invalidating_activity_associated_with_activity_creator) {
    FactoryGirl.create(:associated_with_user_prov_relation,
      relatable_to: invalidating_activity,
      relatable_from: activity_creator
    )
  }

  # (invalidating_activity)-(associatedWith)->(other_software_agent)
  let!(:other_software_agent) {
    FactoryGirl.create(:software_agent, name: "OTHER_SOFTWARE_AGENT")
  }
  let!(:invalidating_activity_associated_with_other_software_agent) {
    FactoryGirl.create(:associated_with_software_agent_prov_relation,
      relatable_from: other_software_agent,
      relatable_to: invalidating_activity
    )
  }

  # (invalidating_activity)-(used)->(invalidating_file)
  let!(:invalidating_file) {
    FactoryGirl.create(:file_version, label: "INVALIDATING_FILE")
  }
  let!(:invalidating_activity_used_invalidating_file) {
    FactoryGirl.create(:used_prov_relation,
      relatable_to: invalidating_file,
      relatable_from: invalidating_activity
    )
  }

  # (deleted_file)-(attributedTo)->(activity.creator)
  let!(:deleted_file_attributed_to_activity_creator) {
    FactoryGirl.create(:attributed_to_user_prov_relation,
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
      let(:provenance_graph) {
        ProvenanceGraph.new(
          focus: focus,
          policy_scope: policy_scope
        )
      }

      context 'nodes' do
        subject{ provenance_graph.nodes }

        it_behaves_like 'ProvenanceGraph includes node', :focus

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes node', :activity
        it_behaves_like 'ProvenanceGraph includes node', :activity_creator
        it_behaves_like 'ProvenanceGraph includes node', :software_agent
        it_behaves_like 'ProvenanceGraph includes node', :generated_file
        it_behaves_like 'ProvenanceGraph includes node', :deleted_file

        # 2 hops
        it_behaves_like 'ProvenanceGraph includes node', :invalidating_activity

        # 3 hops
        it_behaves_like 'ProvenanceGraph includes node', :invalidating_file
        it_behaves_like 'ProvenanceGraph includes node', :other_software_agent
      end

      context 'relationships' do
        subject{ provenance_graph.relationships }

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_used_focus
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_software_agent
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_derived_from_focus
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_derived_from_focus

        # 2 hops
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_associated_with_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_associated_with_software_agent
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_generated_by_activity
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_invalidated_by_invalidating_activity
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_attributed_to_activity_creator

        # 3 hops
        it_behaves_like 'ProvenanceGraph includes relationship', :invalidating_activity_associated_with_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :invalidating_activity_associated_with_other_software_agent
        it_behaves_like 'ProvenanceGraph includes relationship', :invalidating_activity_used_invalidating_file
      end
    end

    context 'max_hops 1' do
      let(:provenance_graph) {
        ProvenanceGraph.new(
          focus: focus,
          max_hops: 1,
          policy_scope: policy_scope,
        )
      }

      context 'nodes' do
        subject{ provenance_graph.nodes }

        it_behaves_like 'ProvenanceGraph includes node', :focus

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes node', :activity
        it_behaves_like 'ProvenanceGraph includes node', :activity_creator
        it_behaves_like 'ProvenanceGraph includes node', :software_agent
        it_behaves_like 'ProvenanceGraph includes node', :generated_file
        it_behaves_like 'ProvenanceGraph includes node', :deleted_file

        # 2 hops
        it_behaves_like 'ProvenanceGraph excludes node', :invalidating_activity

        # 3 hops
        it_behaves_like 'ProvenanceGraph excludes node', :invalidating_file
        it_behaves_like 'ProvenanceGraph excludes node', :other_software_agent
      end

      context 'relationships' do
        subject{ provenance_graph.relationships }

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_used_focus
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_software_agent
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_derived_from_focus
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_derived_from_focus

        # 2 hops
        it_behaves_like 'ProvenanceGraph excludes relationship', :activity_associated_with_activity_creator
        it_behaves_like 'ProvenanceGraph excludes relationship', :activity_associated_with_software_agent
        it_behaves_like 'ProvenanceGraph excludes relationship', :generated_file_generated_by_activity
        it_behaves_like 'ProvenanceGraph excludes relationship', :generated_file_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph excludes relationship', :deleted_file_invalidated_by_invalidating_activity
        it_behaves_like 'ProvenanceGraph excludes relationship', :deleted_file_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_associated_with_activity_creator

        # 3 hops
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_associated_with_other_software_agent
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_used_invalidating_file
      end
    end

    context 'max_hops 2' do
      let(:provenance_graph) {
        ProvenanceGraph.new(
          focus: focus,
          max_hops: 2,
          policy_scope: policy_scope,
        )
      }

      context 'nodes' do
        subject{ provenance_graph.nodes }

        it_behaves_like 'ProvenanceGraph includes node', :focus

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes node', :activity
        it_behaves_like 'ProvenanceGraph includes node', :activity_creator
        it_behaves_like 'ProvenanceGraph includes node', :software_agent
        it_behaves_like 'ProvenanceGraph includes node', :generated_file
        it_behaves_like 'ProvenanceGraph includes node', :deleted_file

        # 2 hops
        it_behaves_like 'ProvenanceGraph includes node', :invalidating_activity

        # 3 hops
        it_behaves_like 'ProvenanceGraph excludes node', :invalidating_file
        it_behaves_like 'ProvenanceGraph excludes node', :other_software_agent
      end

      context 'relationships' do
        subject{ provenance_graph.relationships }

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_used_focus
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_software_agent
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_derived_from_focus
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_derived_from_focus

        # 2 hops
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_associated_with_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_associated_with_software_agent
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_generated_by_activity
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_invalidated_by_invalidating_activity
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_attributed_to_activity_creator
        it_behaves_like 'ProvenanceGraph includes relationship', :invalidating_activity_associated_with_activity_creator

        # 3 hops
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_associated_with_other_software_agent
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_used_invalidating_file
      end
    end

    context 'restrictive policy_scope' do
      let(:provenance_graph) {
        ProvenanceGraph.new(
          focus: focus,
          max_hops: 1,
          policy_scope: Proc.new { |scope| scope.none }
        )
      }

      context 'nodes' do
        subject{ provenance_graph.nodes }

        it_behaves_like 'ProvenanceGraph includes node', :focus, with_included_properties: false

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes node', :activity, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes node', :activity_creator, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes node', :software_agent, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes node', :generated_file, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes node', :deleted_file, with_included_properties: false

        # 2 hops
        it_behaves_like 'ProvenanceGraph excludes node', :invalidating_activity, with_included_properties: false

        # 3 hops
        it_behaves_like 'ProvenanceGraph excludes node', :invalidating_file, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes node', :other_software_agent, with_included_properties: false
      end

      context 'relationships' do
        subject{ provenance_graph.relationships }

        # 1 hop
        it_behaves_like 'ProvenanceGraph includes relationship', :activity_used_focus, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_activity_creator, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes relationship', :focus_attributed_to_software_agent, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes relationship', :generated_file_derived_from_focus, with_included_properties: false
        it_behaves_like 'ProvenanceGraph includes relationship', :deleted_file_derived_from_focus, with_included_properties: false

        # 2 hops
        it_behaves_like 'ProvenanceGraph excludes relationship', :activity_associated_with_activity_creator, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :activity_associated_with_software_agent, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :generated_file_generated_by_activity, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :generated_file_attributed_to_activity_creator, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :deleted_file_invalidated_by_invalidating_activity, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :deleted_file_attributed_to_activity_creator, with_included_properties: false

        # 3 hops
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_associated_with_activity_creator, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_associated_with_other_software_agent, with_included_properties: false
        it_behaves_like 'ProvenanceGraph excludes relationship', :invalidating_activity_used_invalidating_file, with_included_properties: false
      end
    end
  end
end
