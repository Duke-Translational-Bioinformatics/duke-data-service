require 'rails_helper'

describe ApplicationPolicy do
  let(:user) { User.new }
  subject { described_class }

  describe '.new' do
    it 'raises an error for nil user' do
      expect {subject.new(nil, Object)}.to raise_error(Pundit::NotAuthorizedError)
    end

    it 'does not raise an error for a user' do
      expect {subject.new(user, Object)}.not_to raise_error
    end
  end
end

