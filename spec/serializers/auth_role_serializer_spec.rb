require 'rails_helper'

RSpec.describe AuthRoleSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:auth_role) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      permissions_parsed = subject['permissions'].collect { |c| c['id'] }
      is_expected.to have_key('id')
      is_expected.to have_key('name')
      is_expected.to have_key('description')
      is_expected.to have_key('permissions')
      is_expected.to have_key('contexts')
      is_expected.to have_key('is_deprecated')
      expect(subject['id']).to eq(resource.id)
      expect(subject['name']).to eq(resource.name)
      expect(subject['description']).to eq(resource.description)
      expect(subject['contexts']).to eq(resource.contexts)
      expect(subject['is_deprecated']).to eq(resource.is_deprecated)
      expect(permissions_parsed).to eq(resource.permissions)
    end
  end
end
