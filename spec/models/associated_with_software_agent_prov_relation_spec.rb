require 'rails_helper'

RSpec.describe AssociatedWithSoftwareAgentProvRelation, type: :model do
  subject { FactoryGirl.create(:associated_with_software_agent_prov_relation) }
  let(:resource_serializer) { AssociatedWithSoftwareAgentProvRelationSerializer }

  it_behaves_like 'a ProvRelation'

  describe 'validations' do
    it { is_expected.to validate_inclusion_of( :relationship_type ).in_array(['was-associated-with']) }

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
