require 'rails_helper'

RSpec.describe AffiliationSerializer, type: :serializer do
  let(:resource) { FactoryGirl.build(:affiliation) }

  it_behaves_like 'a json serializer' do
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
end
