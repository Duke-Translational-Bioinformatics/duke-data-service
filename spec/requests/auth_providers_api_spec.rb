require 'rails_helper'

describe DDS::V1::AuthProvidersAPI do
  before { allow_any_instance_of(Net::LDAP).to receive(:search).and_raise(Net::LDAP::Error) }
  include_context 'without authentication'
  let(:auth_providers) {[
      FactoryGirl.create(:duke_authentication_service),
      FactoryGirl.create(:openid_authentication_service)
  ]}
  let(:query_params) { '' }
  let(:resource_serializer) { AuthenticationServiceSerializer }

  describe 'authentication providers collection' do
    let(:url) { "/api/v1/auth_providers" }
    let(:payload) {{}}

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
    let(:payload) {{}}
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

  describe 'Auth Provider Affiliates' do
    let(:authentication_service) { FactoryGirl.create(:openid_authentication_service, :with_ldap_identity_provider) }
    let(:authentication_service_id) { authentication_service.id }

    let(:resource) {
      user = FactoryGirl.build(:user)
      user.user_authentication_services.build([{
        uid: user.username,
        authentication_service: authentication_service
      }])
      user
    }
    let(:resource_class) { User }
    let(:resource_uid) { resource.username }
    let(:returned_users) { [resource] }

    describe 'list' do
      include_context 'common headers'

      let(:url) { "/api/v1/auth_providers/#{authentication_service_id}/affiliates" }
      let(:resource_serializer) { AffiliateSerializer }
      let(:expected_response_status) { 200 }

      it_behaves_like 'a GET request' do
        let(:payload) {{
          full_name_contains: resource.last_name
        }}

        it_behaves_like 'an identity_provider dependant authentication_provider resource', authentication_provider_sym: :authentication_service

        it_behaves_like 'an identity provider', returns: :returned_users do
          it_behaves_like 'a listable resource', persisted_resource: false do
            let(:expected_resources) { returned_users }
            let(:expected_list_length) { expected_resources.count }
            let(:serializable_resource) {
              resource
            }
          end
          it_behaves_like 'a paginated resource' do
            let(:returned_users) { extras + [resource] }
            let(:extras) { FactoryGirl.create_list(:user, 5) }
            let(:expected_total_length) { returned_users.count }
          end
          context 'with invalid authentication_service_id' do
            let(:authentication_service_id) { "doesNotExist" }
            let(:resource_class) { AuthenticationService }
            it_behaves_like 'an identified resource'
          end
        end
      end
    end

    describe 'view' do
      include_context 'with authentication'
      let(:url) { "/api/v1/auth_providers/#{authentication_service_id}/affiliates/#{resource_uid}" }
      let(:resource_serializer) { AffiliateSerializer }
      let(:payload) {{
        uid: resource_uid
      }}
      let(:expected_response_status) { 200 }
      subject { get(url, params: payload, headers: headers) }

      it_behaves_like 'an identity_provider dependant authentication_provider resource', authentication_provider_sym: :authentication_service
      it_behaves_like 'an identity provider', returns: :returned_users do
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a viewable resource'
        context 'with invalid authentication_service_id' do
          let(:authentication_service_id) { "doesNotExist" }
          let(:resource_class) { AuthenticationService }
          it_behaves_like 'an identified resource'
        end
      end
      it_behaves_like 'an identified affiliate'
    end

    describe 'create' do
      include_context 'with authentication'
      let(:url) { "/api/v1/auth_providers/#{authentication_service_id}/affiliates/#{resource_uid}/dds_user" }
      let(:resource_serializer) { UserSerializer }
      let(:expected_response_status) { 201 }
      subject { post(url, headers: headers) }

      before do
        expect(current_user).to be
      end

      it_behaves_like 'an identity_provider dependant authentication_provider resource', authentication_provider_sym: :authentication_service

      it_behaves_like 'an identity provider', returns: :returned_users do
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource' do
          let(:called_action) { 'POST' }
          let(:expected_response_status) { 201 }
          it_behaves_like 'an annotate_audits endpoint' do
            let(:called_action) { 'POST' }
            let(:expected_response_status) { 201 }
          end
        end
        it_behaves_like 'a creatable resource' do
          it 'should have a persisted user_authentication_service' do
            expect {
              is_expected.to eq(expected_response_status)
            }.to change{UserAuthenticationService.count}.by(1)
            expect(new_object).to be
            expect(new_object.user_authentication_services.where(authentication_service_id: authentication_service_id)).to exist
          end
        end
        it_behaves_like 'an annotate_audits endpoint' do
          let(:called_action) { 'POST' }
          let(:expected_response_status) { 201 }
        end
        context 'with invalid authentication_service_id' do
          let(:authentication_service_id) { "doesNotExist" }
          let(:resource_class) { AuthenticationService }
          it_behaves_like 'an identified resource'
        end
      end
      it_behaves_like 'an identified affiliate'
      context 'affiliate dds_user already exists' do
        let(:existing_user) { FactoryGirl.create(:user) }
        let(:existing_user_authentication_service) {
          FactoryGirl.create(:user_authentication_service,
            uid: existing_user.username,
            authentication_service: authentication_service,
            user: existing_user
          )
        }
        let(:resource_uid) { existing_user.username }

        it {
          expect(existing_user).to be
          expect(existing_user_authentication_service).to be
          is_expected.to eq(409)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('error')
          expect(response_json['error']).to eq('409')
          expect(response_json).to have_key('code')
          expect(response_json['code']).to eq('not_provided')
          expect(response_json).to have_key('reason')
          expect(response_json['reason']).to eq("Affiliate already registered")
          expect(response_json).to have_key('suggestion')
          expect(response_json['suggestion']).to eq("nothing else needs to be done")
        }
      end
    end
  end
end
