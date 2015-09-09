require 'rails_helper'

RSpec.describe ProjectRole, type: :model do
  it 'should have id as primary key' do
    expect(ProjectRole.primary_key).to eq('id')
  end

  describe 'associations' do
    it 'should have many affiliations' do
      should have_many(:affiliations)
    end
  end

  describe 'validations' do
    it 'should have a unique id' do
      should validate_presence_of(:id)
      should validate_uniqueness_of(:id)
    end

    it 'should have a name' do
      should validate_presence_of(:name)
    end

    it 'should have a description' do
      should validate_presence_of(:description)
    end
  end
end
