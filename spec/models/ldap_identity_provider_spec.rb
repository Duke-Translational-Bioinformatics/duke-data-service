require 'rails_helper'

RSpec.describe LdapIdentityProvider, type: :model do

  subject { auth_provider.identity_provider }
  let(:auth_provider) { FactoryBot.create(:openid_authentication_service, :with_ldap_identity_provider) }
  let(:test_user) { FactoryBot.attributes_for(:user) }

  it { is_expected.to be_an IdentityProvider }

  describe 'validations' do
    it { is_expected.to validate_presence_of :ldap_base }
  end

  describe '#affiliate' do
    let(:ldap_returns) { [test_user] }
    include_context 'mocked ldap', returns: :ldap_returns
    subject { auth_provider.identity_provider.affiliate(test_user[:username]) }

    it {
      is_expected.to be
      is_expected.to be_a User
      is_expected.not_to be_persisted
      expect(subject.display_name).to eq test_user[:display_name]
    }
  end

  describe '#affiliates' do
    context 'full_name_contains' do
      context 'not provided' do
        subject { auth_provider.identity_provider.affiliates }
        before { expect(auth_provider.identity_provider).not_to receive(:ldap_search) }
        it { is_expected.to eq [] }
      end

      context 'less than 3 characters' do
        subject { auth_provider.identity_provider.affiliates(
          'a'*2
        ) }
        before { expect(auth_provider.identity_provider).not_to receive(:ldap_search) }
        it { is_expected.to eq [] }
      end

      context 'is 3 characters' do
        let(:ldap_returns) { [test_user] }
        include_context 'mocked ldap', returns: :ldap_returns
        subject { auth_provider.identity_provider.affiliates('foo') }
        before { expect(auth_provider.identity_provider).to receive(:ldap_search).and_call_original }
        it { is_expected.not_to be_empty }
      end

      context 'greater than 3 characters' do
        context 'missing uid' do
          let(:test_user) { FactoryBot.attributes_for(:user).reject{|k| k == :username } }
          let(:ldap_returns) { [test_user] }
          include_context 'mocked ldap', returns: :ldap_returns
          subject { auth_provider.identity_provider.affiliates(
            test_user[:last_name]
          ) }

          it {
            is_expected.to be_a Array
            expect(subject.length).to eq 0
          }
        end

        context 'missing mail' do
          let(:test_user) { FactoryBot.attributes_for(:user).reject{|k| k == :email } }
          let(:ldap_returns) { [test_user] }
          include_context 'mocked ldap', returns: :ldap_returns
          subject { auth_provider.identity_provider.affiliates(
            test_user[:last_name]
          ) }

          it {
            is_expected.to be_a Array
            expect(subject.length).to be > 0
            subject.each do |response|
              expect(response).to be_a User
              expect(response).not_to be_persisted
              expect(response.display_name).to eq test_user[:display_name]
              expect(response.email).not_to be
            end
          }
        end

        context 'complete record' do
          let(:ldap_returns) { [test_user] }
          include_context 'mocked ldap', returns: :ldap_returns
          subject { auth_provider.identity_provider.affiliates(
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
end
