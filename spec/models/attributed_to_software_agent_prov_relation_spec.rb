require 'rails_helper'

RSpec.describe AttributedToSoftwareAgentProvRelation, type: :model do
  subject { FactoryGirl.create(:attributed_to_software_agent_prov_relation) }
  let(:resource_serializer) { AttributedToSoftwareAgentProvRelationSerializer }
  let(:expected_relationship_type) { 'was-attributed-to' }
  it_behaves_like 'a ProvRelation'

  describe 'validations' do
    it { is_expected.to allow_value('FileVersion').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('DataFile').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Container').for(:relatable_from_type) }

    it { is_expected.to allow_value('SoftwareAgent').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('FileVersion').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_to_type) }
  end
end
