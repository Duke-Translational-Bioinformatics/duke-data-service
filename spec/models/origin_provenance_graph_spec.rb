require 'rails_helper'

RSpec.describe OriginProvenanceGraph do
  include_context 'mock all Uploads StorageProvider'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob
  let(:policy_scope) { Proc.new {|scope| scope } }

  # (fv1ga)-[generated]->(fv1)
  let!(:fv1) { FactoryBot.create(:file_version, label: "FV1") }
  let!(:fv1ga) { FactoryBot.create(:activity, name: "FV1GA") }
  let!(:fv1ga_generated_fv1) {
    FactoryBot.create(:generated_by_activity_prov_relation,
      relatable_from: fv1,
      relatable_to: fv1ga
    )
 }

  # (fv2)-(generatedBy)->(fv2ga)-[used]-(used_by_fvg2a)
  let!(:fv2) { FactoryBot.create(:file_version, label: "FV2") }
  let!(:fv2ga) { FactoryBot.create(:activity, name: "FV2GA") }
  let!(:fv2ga_generated_fv2) {
    FactoryBot.create(:generated_by_activity_prov_relation,
      relatable_from: fv2,
      relatable_to: fv2ga
    )
  }
  let!(:used_by_fv2ga) { FactoryBot.create(:file_version, label: "USED_BY_FV2GA") }
  let!(:fv2ga_used_used_by_fv2ga) {
    FactoryBot.create(:used_prov_relation,
      relatable_to: used_by_fv2ga,
      relatable_from: fv2ga
    )
  }

  # (fv2)-(derivedFrom)->(fv2_derived_from)
  let!(:fv2_derived_from) { FactoryBot.create(:file_version, label: "FV2_DERIVED_FROM") }
  let!(:fv2_derived_from_fv2_derived_from) {
    FactoryBot.create(:derived_from_file_version_prov_relation,
      relatable_to: fv2_derived_from,
      relatable_from: fv2
    )
  }
  let!(:file_versions) { [ {id: fv1.id}, {id: fv2.id} ] }

  it { expect(described_class).to include(ActiveModel::Serialization) }

  context 'initialization' do
    it {
      expect{
        described_class.new
      }.to raise_error(ArgumentError)
    }

    it {
      expect{
        described_class.new(file_versions: file_versions)
      }.to raise_error(ArgumentError)
    }

    it {
      expect {
        described_class.new(file_versions: file_versions, policy_scope: policy_scope)
      }.not_to raise_error
    }
  end

  context 'instantiations' do
    context 'default' do
      subject{
        OriginProvenanceGraph.new(
          file_versions: file_versions,
          policy_scope: policy_scope
        )
      }

      it_behaves_like 'A ProvenanceGraph', includes_node_syms: [
          :fv1,
          :fv1ga,
          :fv2,
          :fv2ga,
          :used_by_fv2ga,
          :fv2_derived_from
        ], includes_relationship_syms: [
          :fv1ga_generated_fv1,
          :fv2ga_generated_fv2,
          :fv2ga_used_used_by_fv2ga,
          :fv2_derived_from_fv2_derived_from
        ]
    end

    context 'restrictive policy_scope' do
      subject{
        OriginProvenanceGraph.new(
          file_versions: file_versions,
          policy_scope: Proc.new { |scope| scope.none }
        )
      }

      it_behaves_like 'A ProvenanceGraph', with_restricted_properties: true,
        includes_node_syms: [
          :fv1,
          :fv1ga,
          :fv2,
          :fv2ga,
          :used_by_fv2ga,
          :fv2_derived_from
        ], includes_relationship_syms: [
          :fv1ga_generated_fv1,
          :fv2ga_generated_fv2,
          :fv2ga_used_used_by_fv2ga,
          :fv2_derived_from_fv2_derived_from
        ]
    end
  end
end
