shared_context 'mocked ldap' do |returns:|
  let(:entry_users) { send(returns) }
  let(:attr_map) {{
    uid: :username,
    givenName: :first_name,
    sn: :last_name,
    mail: :email,
    displayName: :display_name
  }}
  let(:expected_entries) {
    entry_users.map { |test_user|
      expected_entry = Net::LDAP::Entry.new
      attr_map.each_pair do |ldap_attr, model_attr|
        expected_entry[ldap_attr] = test_user[model_attr] if test_user[model_attr]
      end
      expected_entry
    }
  }
  before do
    allow_any_instance_of(Net::LDAP).to receive(:search) { |&block|
      expected_entries.each &block
    }
  end
end

shared_examples 'an identity_provider dependant authentication_provider resource' do |authentication_provider_sym:|
  let(:authentication_provider) { send(authentication_provider_sym) }

  context 'identity provider communication failure' do
    let(:expected_response_status) { 503 } #Service Unavailable
    let(:expected_reason) { "identity provider communication failure" }
    let(:expected_suggestion) { 'please try again in a few minutes, or report an issue' }

    it {
      is_expected.to eq(expected_response_status)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('code')
      expect(response_json['code']).to eq('not_provided')
      expect(response_json).to have_key('error')
      expect(response_json['error']).to eq("#{expected_response_status}")
      expect(response_json).to have_key('reason')
      expect(response_json['reason']).to eq(expected_reason)
      expect(response_json).to have_key('suggestion')
      expect(response_json['suggestion']).to eq(expected_suggestion)
    }
  end

  context 'AuthenticationService does not have a supported IdentityProvider' do
    let(:expected_response_status) { 400 }
    let(:expected_reason) { "authentication provider does not support affilate searches" }
    let(:expected_suggestion) { 'perhaps you are using the wrong authentication provider' }

    before do
      authentication_provider.identity_provider.destroy
      authentication_provider.reload
    end

    it {
      expect(authentication_provider.identity_provider).to be_nil
      is_expected.to eq(expected_response_status)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('code')
      expect(response_json['code']).to eq('not_provided')
      expect(response_json).to have_key('error')
      expect(response_json['error']).to eq("#{expected_response_status}")
      expect(response_json).to have_key('reason')
      expect(response_json['reason']).to eq(expected_reason)
      expect(response_json).to have_key('suggestion')
      expect(response_json['suggestion']).to eq(expected_suggestion)
    }
  end
end

shared_examples 'an identity provider' do |returns:|
  include_context 'mocked ldap', returns: returns

  it {
    is_expected.to eq(expected_response_status)
  }
end

shared_examples 'an identified affiliate' do
  let(:empty_response) {[]}
  include_context 'mocked ldap', returns: :empty_response

  it 'should return 404 with error when affiliate not found with uid' do
    is_expected.to eq(404)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('code')
    expect(response_json['code']).to eq('not_provided')
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('404')
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq("Affiliate Not Found")
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq("you may have mistyped the uid")
  end
end
