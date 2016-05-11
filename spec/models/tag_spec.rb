require 'rails_helper'

RSpec.describe Tag, type: :model do
  subject { FactoryGirl.create(:tagged_file) }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:taggable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:taggable) }
  end

end
