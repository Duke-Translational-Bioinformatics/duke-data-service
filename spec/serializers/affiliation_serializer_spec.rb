require 'rails_helper'

RSpec.describe AffiliationSerializer, type: :serializer do
  let(:serializer) { AffiliationSerializer.new(resource) }
  let(:resource) { FactoryGirl.build(:affiliation) }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end

  it 'should have expected keys and values' do
    is_expected.to eq({
      'project' => {
        'id' => resource.project_id
      },
      'user' => {
        'id' => resource.user.id,
        'full_name' => resource.user.display_name,
        'email' => resource.user.email
      },
      'project_role' => {
        'id' => resource.project_role.id,
        'name' => resource.project_role.name
      }
    })
  end
end
