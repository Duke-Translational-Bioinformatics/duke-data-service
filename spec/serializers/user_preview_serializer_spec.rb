require 'rails_helper'

RSpec.describe UserPreviewSerializer, type: :serializer do
  let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:resource) { user_authentication_service.user }
  let(:expected_attributes) {{
    'id' => resource.id,
    'username' => resource.username,
    'full_name' => resource.display_name
  }}
  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
