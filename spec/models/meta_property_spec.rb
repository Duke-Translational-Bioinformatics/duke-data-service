require 'rails_helper'

RSpec.describe MetaProperty, type: :model do

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:meta_template) }
    it { is_expected.to belong_to(:property) }
  end

  describe 'validations' do
    let!(:existing_tag_for_uniqueness_validation) { FactoryGirl.create(:meta_property) }
    it { is_expected.to validate_presence_of(:meta_template) }
    it { is_expected.to validate_presence_of(:property) }
    it { is_expected.to validate_presence_of(:value) }

    it { is_expected.to validate_uniqueness_of(:property).scoped_to(:meta_template_id).case_insensitive }
  end
end
