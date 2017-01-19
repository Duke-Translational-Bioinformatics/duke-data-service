require 'rails_helper'

RSpec.describe AssociatedWithSoftwareAgentProvRelation, type: :model do
  subject { FactoryGirl.create(:associated_with_software_agent_prov_relation) }
  let(:resource_serializer) { AssociatedWithSoftwareAgentProvRelationSerializer }
  let(:expected_relationship_type) { 'was-associated-with' }

  it_behaves_like 'a ProvRelation' do
    let(:expected_kind) { 'dds-relation-was-associated-with' }
    let(:serialized_kind) { true }
    let(:kinded_class) { AssociatedWithProvRelation }
  end

  describe 'validations' do
    it { is_expected.to allow_value('SoftwareAgent').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Activity').for(:relatable_from_type) }

    it { is_expected.to allow_value('Activity').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_to_type) }
  end
end
