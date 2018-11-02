require 'rails_helper'

RSpec.describe LdapIdentityProvider, type: :model do

  subject { auth_provider.identity_provider }
  let(:auth_provider) { FactoryBot.create(:openid_authentication_service, :with_ldap_identity_provider) }
  let(:test_user) { FactoryBot.build(:user) }
  let(:test_user_attrs) { test_user.attributes.symbolize_keys }
  let(:array_of_users) { [test_user] }

  it_behaves_like 'an IdentityProvider'

  describe 'validations' do
    it { is_expected.to validate_presence_of :ldap_base }
  end

  describe '#affiliate' do
    subject { auth_provider.identity_provider.affiliate(username) }
    let(:username) { test_user.username }
    before(:example) do
      expect(auth_provider.identity_provider).to receive(:ldap_search).with(filter: {username: username}).and_return(array_of_users)
    end

    it { is_expected.to eq test_user }

    context 'search returns empty array' do
      let(:array_of_users) {[]}
      it { is_expected.to be_nil }
    end
  end

  describe '#affiliates' do
    context 'username' do
      let(:affiliates) { auth_provider.identity_provider.affiliates(username: username) }
      let(:username) { test_user.username }
      before(:example) do
        expect(auth_provider.identity_provider).to receive(:ldap_search).with(filter: {username: username}).and_return(array_of_users)
      end
      it { expect(affiliates).to eq array_of_users }
    end

    context 'email' do
      let(:affiliates) { auth_provider.identity_provider.affiliates(email: email) }
      let(:email) { test_user.email }
      before(:example) do
        expect(auth_provider.identity_provider).to receive(:ldap_search).with(filter: {email: email}).and_return(array_of_users)
      end
      it { expect(affiliates).to eq array_of_users }
    end

    context 'full_name_contains' do
      context 'not provided' do
        subject { auth_provider.identity_provider.affiliates }
        before { expect(auth_provider.identity_provider).not_to receive(:ldap_search) }
        it { is_expected.to eq [] }
      end

      context 'less than 3 characters' do
        subject { auth_provider.identity_provider.affiliates(
          full_name_contains: 'a'*2
        ) }
        before { expect(auth_provider.identity_provider).not_to receive(:ldap_search) }
        it { is_expected.to eq [] }
      end

      context 'is 3 characters' do
        subject { auth_provider.identity_provider.affiliates(full_name_contains: test_user.last_name) }
        let(:full_name_contains) { test_user.last_name[0,3] }
        let(:array_of_users) { [test_user] }
        before(:example) do
          expect(auth_provider.identity_provider).to receive(:ldap_search).with(filter: {full_name_contains: test_user.last_name}).and_return(array_of_users)
        end
        it { is_expected.to eq array_of_users }
      end
    end
  end

  describe '#ldap_entry_to_user' do
    it { is_expected.to respond_to(:ldap_entry_to_user).with(1).argument }
    it { is_expected.not_to respond_to(:ldap_entry_to_user).with(0).arguments }

    context 'when called' do
      let(:ldap_entry_to_user) { subject.ldap_entry_to_user(ldap_entry) }
      let(:ldap_entry) {
        e = Net::LDAP::Entry.new
        entry_hash.each_pair {|k, v| e[k] = v if v}
        e
      }
      let(:entry_hash) {{
        uid: user_attrs[:username],
        givenname: user_attrs[:first_name],
        sn: user_attrs[:last_name],
        mail: user_attrs[:email],
        displayname: user_attrs[:display_name]
      }}
      let(:user_attrs) { test_user_attrs }
      it { expect(ldap_entry.attribute_names).to include(*entry_hash.keys) }
      it { expect(ldap_entry_to_user).to be_a(User) }
      it { expect(ldap_entry_to_user.username).to eq entry_hash[:uid] }
      it { expect(ldap_entry_to_user.first_name).to eq entry_hash[:givenname] }
      it { expect(ldap_entry_to_user.last_name).to eq entry_hash[:sn] }
      it { expect(ldap_entry_to_user.email).to eq entry_hash[:mail] }
      it { expect(ldap_entry_to_user.display_name).to eq entry_hash[:displayname] }

      context 'incomplete entry' do
        let(:user_attrs) { test_user_attrs.reject {|k,v| k == missing_attr} }
        context 'with entry without uid' do
          let(:missing_attr) { :username }
          it { expect(ldap_entry[:uid]).to eq [] }
          it { expect(ldap_entry_to_user).to be_nil }
        end

        context 'with entry without givenname' do
          let(:missing_attr) { :first_name }
          it { expect(ldap_entry[:givenname]).to eq [] }
          it { expect(ldap_entry_to_user).to be_a(User) }
          it { expect(ldap_entry_to_user.first_name).to be_nil }
        end

        context 'with entry without sn' do
          let(:missing_attr) { :last_name }
          it { expect(ldap_entry[:sn]).to eq [] }
          it { expect(ldap_entry_to_user).to be_a(User) }
          it { expect(ldap_entry_to_user.last_name).to be_nil }
        end

        context 'with entry without mail' do
          let(:missing_attr) { :email }
          it { expect(ldap_entry[:mail]).to eq [] }
          it { expect(ldap_entry_to_user).to be_a(User) }
          it { expect(ldap_entry_to_user.email).to be_nil }
        end

        context 'with entry without displayname' do
          let(:missing_attr) { :display_name }
          it { expect(ldap_entry[:displayname]).to eq [] }
          it { expect(ldap_entry_to_user).to be_a(User) }
          it { expect(ldap_entry_to_user.display_name).to be_nil }
        end
      end
    end
  end

  describe '#ldap_search' do
    let(:ldap_search) { subject.ldap_search(filter: filter_hash) }
    let(:filter_hash) { {} }
    it { is_expected.to respond_to(:ldap_search).with_keywords(:filter) }
    it { is_expected.not_to respond_to(:ldap_search).with(0).arguments }

    context 'when called' do
      let(:ldap_mock) { instance_double("Net::LDAP") }
      let(:entry_mock) { instance_double("Net::LDAP::Entry") }
      let(:filter_mock) { instance_double("Net::LDAP::Filter") }
      let(:user_mock) { instance_double("User") }
      let(:ldap_attributes) { %w(uid duDukeID givenName sn mail displayName) }
      before(:example) do
        is_expected.to receive(:ldap_conn).and_return(ldap_mock)
        is_expected.to receive(:ldap_filter).with(filter_hash).and_return(filter_mock)
        expect(ldap_mock).to receive(:search)
          .with(filter: filter_mock, attributes: a_collection_containing_exactly(*ldap_attributes), size: 500, return_results: false)
          .and_yield(entry_mock)
          .and_return(true)
        is_expected.to receive(:ldap_entry_to_user).with(entry_mock).and_return(user_mock)
      end
      it { expect(ldap_search).to eq [user_mock] }

      context 'and #ldap_entry_to_user returns nil' do
        let(:user_mock) { nil }
        it { expect(ldap_search).to eq [] }
      end
    end
  end

  describe '#ldap_filter' do
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

    context 'with email filter' do
      let(:filter_hash) { {email: mail} }
      let(:mail) { FactoryBot.attributes_for(:user)[:email] }
      it { expect(ldap_filter).to be_a Net::LDAP::Filter }
      it { expect(ldap_filter.to_s).to eq "(mail=#{mail})" }
    end

    context 'with full_name_contains filter' do
      let(:filter_hash) { {full_name_contains: last_name} }
      let(:last_name) { FactoryBot.attributes_for(:user)[:last_name] }
      it { expect(ldap_filter).to be_a Net::LDAP::Filter }
      it { expect(ldap_filter.to_s).to eq "(displayName=*#{last_name}*)" }
    end
  end

  describe '#ldap_conn' do
    let(:ldap_conn) { subject.ldap_conn }
    it { is_expected.to respond_to(:ldap_conn).with(0).arguments }
    it { expect(ldap_conn).to be_a Net::LDAP }
    it { expect(ldap_conn.host).to eq subject.host }
    it { expect(ldap_conn.port).to eq subject.port }
    it { expect(ldap_conn.base).to eq subject.ldap_base }
    it 'is cached' do
      expect(ldap_conn).to eq subject.ldap_conn
    end
  end
end
