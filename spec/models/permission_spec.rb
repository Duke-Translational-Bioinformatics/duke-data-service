require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Permission, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:permission)}

    it 'should require a title' do
      should validate_presence_of(:title)
    end

    it 'should require a description' do
      should validate_presence_of(:description)
    end
  end

  describe 'serialization' do
    subject {FactoryGirl.create(:permission)}

    it 'should serialize to json' do
      serializer = PermissionSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('description')
      expect(parsed_json['id']).to eq(subject.title)
      expect(parsed_json['description']).to eq(subject.description)
    end
  end

end
