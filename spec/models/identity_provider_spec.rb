require 'rails_helper'

RSpec.describe IdentityProvider, type: :model do
  subject { IdentityProvider.new }

  describe 'validations' do
    it { is_expected.to validate_presence_of :host }
    it { is_expected.to validate_presence_of :port }
  end
end
