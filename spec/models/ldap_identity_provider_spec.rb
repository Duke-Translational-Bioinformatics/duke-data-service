require 'rails_helper'

RSpec.describe LdapIdentityProvider, type: :model do

  subject { auth_provider.identity_provider }
  let(:auth_provider) { FactoryGirl.create(:openid_authentication_service, :with_ldap_identity_provider) }
  let(:test_user) { FactoryGirl.attributes_for(:user) }

  describe 'validations' do
    it { is_expected.to validate_presence_of :ldap_base }
  end

  describe 'affiliate' do
    it { is_expected.to respond_to(:affiliate) }
    context 'without authentication_service' do
      it {
        expect{
          subject.affiliate
        }.to raise_error(ArgumentError)
      }
    end

    context 'without uid' do
      it {
        expect{
          subject.affiliate(auth_provider)
        }.to raise_error(ArgumentError)
      }
    end

    context 'with uid and authentication_service' do
      let(:ldap_returns) { [test_user] }
      include_context 'mocked ldap', returns: :ldap_returns
      subject { auth_provider.identity_provider.affiliate(auth_provider, test_user[:username]) }

      it {
        is_expected.to be
        is_expected.to be_a User
        is_expected.not_to be_persisted
        expect(subject.display_name).to eq test_user[:display_name]
      }
    end
  end

  describe 'affiliates' do
    it { is_expected.to respond_to(:affiliates) }

    it {
      expect{
        subject.affiliates
      }.to raise_error(ArgumentError)
    }

    context 'full_name_contains' do
      context 'not provided' do
        subject { auth_provider.identity_provider.affiliates(auth_provider) }
        it {
          is_expected.to be_a Array
          expect(subject.length).to eq 0
        }
      end

      context 'less than 3 characters' do
        subject { auth_provider.identity_provider.affiliates(
          auth_provider,
          'a'*2
        ) }
        it {
          is_expected.to be_a Array
          expect(subject.length).to eq 0
        }
      end

      context 'greater than 3 characters' do
        let(:ldap_returns) { [test_user] }
        include_context 'mocked ldap', returns: :ldap_returns
        subject { auth_provider.identity_provider.affiliates(
          auth_provider,
          test_user[:last_name]
        ) }

        it {
          is_expected.to be_a Array
          expect(subject.length).to be > 0
          subject.each do |response|
            expect(response).to be_a User
            expect(response).not_to be_persisted
            expect(response.display_name).to eq test_user[:display_name]
          end
        }
      end
    end
  end
end
