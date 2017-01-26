shared_context 'mocked ldap' do
  let(:expected_entry) {
    expected_entry = Net::LDAP::Entry.new
    expected_entry[:uid] = test_user.username
    expected_entry[:givenName] = test_user.display_name
    expected_entry[:sn] = test_user.last_name
    expected_entry[:mail] = test_user.email
    expected_entry[:displayName] = test_user.display_name
    expected_entry
  }
  before do
    allow_any_instance_of(Net::LDAP).to receive(:search).and_return([expected_entry])
  end
end
