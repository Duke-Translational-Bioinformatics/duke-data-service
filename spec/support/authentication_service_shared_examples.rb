shared_examples 'an authentication service' do
  describe 'associations' do
    it {
      is_expected.to have_many(:user_authentication_services)
    }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :service_id }
    it { is_expected.to validate_presence_of :base_uri }
  end
end
