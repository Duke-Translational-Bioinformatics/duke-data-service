require 'rails_helper'

RSpec.describe AffiliateAuthenticationServiceSerializer, type: :serializer do
  describe 'duke_authentication_service' do
      let(:resource) { FactoryBot.create(:duke_authentication_service) }
      it_behaves_like 'an authentication_service_preview_serializer serializable resource' do
        let(:expected_attributes) {{
          'id' => resource.id,
          'name' => resource.name
        }}
      end
  end

  describe 'openid_authentication_service' do
    let(:resource) { FactoryBot.create(:openid_authentication_service) }
    it_behaves_like 'an authentication_service_preview_serializer serializable resource' do
      let(:expected_attributes) {{
        'id' => resource.id,
        'name' => resource.name
      }}
    end
  end
end
