require 'rails_helper'

RSpec.describe AttributedToUserProvRelation, type: :model do
  subject { FactoryGirl.create(:attributed_to_user_prov_relation) }
  let(:resource_serializer) { AttributedToUserProvRelationSerializer }

  it_behaves_like 'a ProvRelation'

  describe 'validations' do
    it { is_expected.to validate_inclusion_of( :relationship_type ).in_array(['was-attributed-to']) }

    it { is_expected.to allow_value('FileVersion').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('DataFile').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Container').for(:relatable_from_type) }

    it { is_expected.to allow_value('User').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('FileVersion').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_to_type) }
  end
end
