require 'rails_helper'

RSpec.describe UsedProvRelation, type: :model do
  subject { FactoryGirl.create(:used_prov_relation) }
  let(:resource_serializer) { UsedProvRelationSerializer }

  it_behaves_like 'a ProvRelation'

  describe 'validations' do
    it { is_expected.to validate_inclusion_of( :relationship_type ).in_array(['used']) }
    it { is_expected.to allow_value('Activity').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.to allow_value('FileVersion').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
  end
end
