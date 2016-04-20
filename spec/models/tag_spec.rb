require 'rails_helper'

RSpec.describe Tag, type: :model do
  subject { FactoryGirl.create(:tag) }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:taggable) }
    it { is_expected.to have_many(:project_permissions).through(:taggable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:taggable) }
  end

  it 'should set default attribute' do
    expect(subject.taggable_type).to eq('DataFile')
  end

end
