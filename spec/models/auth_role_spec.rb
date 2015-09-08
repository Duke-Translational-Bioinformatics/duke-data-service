require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe AuthRole, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:auth_role)}

    it 'should require a unique id' do
      should validate_presence_of(:id)
      should validate_uniqueness_of(:id)
    end

    it 'should require a name' do
      should validate_presence_of(:name)
    end

    it 'should require a description' do
      should validate_presence_of(:description)
    end

    it 'should require at least one permission' do
      should validate_presence_of(:permissions)
      should allow_value(['foo']).for(:permissions)
      should allow_value(['foo', 'bar']).for(:permissions)
      should_not allow_value([]).for(:permissions)
    end

    it 'should require at least one context' do
      should validate_presence_of(:contexts)
      should allow_value(['foo']).for(:contexts)
      should allow_value(['foo', 'bar']).for(:contexts)
      should_not allow_value([]).for(:contexts)
    end
  end

  describe 'queries' do
    let(:query_context) {'findme'}
    let!(:with_context) { FactoryGirl.create_list(:auth_role, 5, contexts: [query_context]) }
    let!(:others) { FactoryGirl.create_list(:auth_role, 5) }

    it 'should support with_context' do
      expect(AuthRole).to respond_to 'with_context'
      found_with_context = AuthRole.with_context(query_context)
      expect(found_with_context.count).to eq(with_context.length)
      found_with_context.each do |ar|
        expect(ar.contexts).to include(query_context)
      end
    end
  end

  #{
  #  "id": "system_admin",
  #  "name": "System Admin",
  #  "description": "Can perform all system operations across all projects",
  #  "permissions": [ "system_admin" ],
  #  "contexts": [ "system" ], // Contexts in which role is relevant (i.e. "system" or "project"),
  #  "is_deprecated": false // If deprecated, cannot be granted, but show for existing users who have this role
  #},
  describe 'serialization' do
    subject {FactoryGirl.create(:auth_role)}

    it 'should serialize to json' do
      serializer = AuthRoleSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('description')
      expect(parsed_json).to have_key('permissions')
      expect(parsed_json).to have_key('contexts')
      expect(parsed_json).to have_key('is_deprecated')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['description']).to eq(subject.description)
      expect(parsed_json['permissions']).to eq(subject.permissions)
      expect(parsed_json['contexts']).to eq(subject.contexts)
      expect(parsed_json['is_deprecated']).to eq(subject.is_deprecated)
    end
  end
end
