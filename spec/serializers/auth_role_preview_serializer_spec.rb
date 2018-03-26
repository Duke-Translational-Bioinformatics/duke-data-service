require 'rails_helper'

RSpec.describe AuthRolePreviewSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:auth_role) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'description' => resource.description
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
