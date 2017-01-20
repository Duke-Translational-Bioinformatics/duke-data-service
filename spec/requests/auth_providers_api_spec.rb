require 'rails_helper'

describe DDS::V1::AuthProvidersAPI do
  include_context 'without authentication'
  let(:auth_providers) {[
      FactoryGirl.create(:duke_authentication_service),
      FactoryGirl.create(:openid_authentication_service)
  ]}
  let(:query_params) { '' }
  let(:resource_serializer) { AuthenticationServiceSerializer }

  describe 'authentication providers collection' do
    let(:url) { "/api/v1/auth_providers" }

    it_behaves_like 'a GET request' do
      let(:expected_resources) { auth_providers }

      before do
        auth_providers.each do |auth_provider|
          expect(auth_provider).to be_persisted
        end
      end

      it_behaves_like 'a listable resource' do
        let(:resource) { auth_providers.first }
        let(:resource_class) { DukeAuthenticationService }
        let(:expected_list_length) { auth_providers.length }
      end

      it_behaves_like 'a listable resource' do
        let(:resource) { auth_providers.last }
        let(:resource_class) { OpenidAuthenticationService }
        let(:expected_list_length) { auth_providers.length }
      end

      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { AuthenticationService.all.count }
        let(:extras) {
          FactoryGirl.create_list(:duke_authentication_service, 3) +
            FactoryGirl.create_list(:openid_authentication_service, 3)
        }
      end
    end
  end

  describe 'authentication provider instance' do
    let(:url) { "/api/v1/auth_providers/#{resource_id}" }
    let(:resource_id) { resource.id }

    context 'duke_authentication_service' do
      let(:resource) { auth_providers.first }
      let(:resource_class) { AuthenticationService }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a viewable resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) { "doesNotExist" }
        end
      end
    end

    context 'openid_authentication_service' do
      let(:resource) { auth_providers.last }
      let(:resource_class) { AuthenticationService }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a viewable resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) { "doesNotExist" }
        end
      end
    end
  end
end
