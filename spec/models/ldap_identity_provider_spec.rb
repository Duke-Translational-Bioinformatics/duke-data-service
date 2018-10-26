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
        context 'incomplete record' do
          let(:test_user) { FactoryBot.attributes_for(:user).reject{|k| k == missing_attr } }
          let(:ldap_returns) { [test_user] }
          include_context 'mocked ldap', returns: :ldap_returns
          subject { auth_provider.identity_provider.affiliates(
            full_name_contains
          ) }
          let(:full_name_contains) { test_user[:last_name] }
          let(:affiliate) { subject.first }
          context 'missing uid' do
            let(:missing_attr) { :username }
            it { is_expected.to eq [] }
          end

          context 'is still valid' do
            before(:example) do
              is_expected.to be_a Array
              expect(subject.length).to eq 1
              expect(affiliate).to be_a(User)
              expect(affiliate).not_to be_persisted
              expect(affiliate.username).to eq test_user[:username]
            end
            context 'when missing mail' do
              let(:missing_attr) { :email }
              it { expect(affiliate.email).to be_nil }
            end
            context 'when missing givenName' do
              let(:missing_attr) { :first_name }
              it { expect(affiliate.first_name).to be_nil }
            end
            context 'when missing sn' do
              let(:full_name_contains) { test_user[:first_name] }
              let(:missing_attr) { :last_name }
              it { expect(affiliate.last_name).to be_nil }
            end
            context 'when missing displayName' do
              let(:missing_attr) { :display_name }
              it { expect(affiliate.display_name).to be_nil }
            end
          end
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

  describe "#ldap_filter" do
    let(:ldap_filter) { subject.ldap_filter(filter_hash) }
    let(:filter_hash) { {} }
    it { is_expected.to respond_to(:ldap_filter).with(1).argument }
    it { is_expected.not_to respond_to(:ldap_filter).with(0).arguments }

    context 'with empty filter hash' do
      it { expect(ldap_filter).to eq nil }
    end

    context 'with username filter' do
      let(:filter_hash) { {username: uid} }
      let(:uid) { FactoryBot.attributes_for(:user)[:username] }
      it { expect(ldap_filter).to be_a Net::LDAP::Filter }
      it { expect(ldap_filter.to_s).to eq "(uid=#{uid})" }
    end

    context 'with full_name_contains filter' do
      let(:filter_hash) { {full_name_contains: last_name} }
      let(:last_name) { FactoryBot.attributes_for(:user)[:last_name] }
      it { expect(ldap_filter).to be_a Net::LDAP::Filter }
      it { expect(ldap_filter.to_s).to eq "(displayName=*#{last_name}*)" }
    end
  end
end
