require 'rails_helper'

RSpec.describe UsedProvRelation, type: :model do
  subject { FactoryGirl.create(:used_prov_relation) }
  let(:resource_serializer) { UsedProvRelationSerializer }
  let(:expected_relationship_type) { 'used' }

  it_behaves_like 'a ProvRelation'

  describe 'validations' do
    it { is_expected.to allow_value('Activity').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.to allow_value('FileVersion').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
  end
end
