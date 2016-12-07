require 'rails_helper'

RSpec.describe Search::UserSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:user) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'username' => resource.username,
    'email' => resource.email,
    'first_name' => resource.first_name,
    'last_name' => resource.last_name
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
