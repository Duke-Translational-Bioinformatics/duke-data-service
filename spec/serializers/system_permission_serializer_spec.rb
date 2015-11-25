require 'rails_helper'

RSpec.describe SystemPermissionSerializer, type: :serializer do
  let(:resource) { FactoryGirl.build(:system_permission) }
  let(:serializer) { SystemPermissionSerializer.new resource }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end

  it 'should have expected keys and values' do
    is_expected.to have_key('user')
    is_expected.to have_key('auth_role')
    expect(subject['user']).to eq({
      'id' => resource.user.id,
      'username' => resource.user.username,
      'full_name' => resource.user.display_name
    })
    expect(resource.auth_role).to be
    expect(subject['auth_role']).to eq({
      'id' => resource.auth_role.id,
      'name' => resource.auth_role.name,
      'description' => resource.auth_role.description
    })
  end
end
