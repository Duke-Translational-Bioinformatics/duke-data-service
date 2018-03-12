require 'rails_helper'

RSpec.describe AffiliateSerializer, type: :serializer do
  let(:user_authentication_service) { FactoryBot.create(:user_authentication_service, :populated) }
  let(:resource) { user_authentication_service.user }
  let(:expected_attributes) {{
    'uid' => resource.username,
    'first_name' => resource.first_name,
    'last_name' => resource.last_name,
    'full_name' => resource.display_name,
    'email' => resource.email
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
