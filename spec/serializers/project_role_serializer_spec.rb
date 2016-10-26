require 'rails_helper'

RSpec.describe ProjectRoleSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:project_role) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'description' => resource.description,
    'is_deprecated' => resource.is_deprecated
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
