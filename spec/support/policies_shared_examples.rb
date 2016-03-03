shared_context 'policy declarations' do
  subject { described_class }
  let(:record_class) { 
    described_class.name.gsub(/Policy$/,'').constantize 
  }
  let(:resolved_scope) {
    described_class::Scope.new(user, record_class.all).resolve
  }
end

shared_examples 'system_permission can access' do |record_sym|
  let(:user) { FactoryGirl.create(:system_permission).user }
  let(:record) { send(record_sym) }

  describe '.scope' do
    it { expect(resolved_scope).to include(record) }
  end
  permissions :show?, :create?, :update?, :destroy? do
    it { is_expected.to permit(user, record) }
  end
end
