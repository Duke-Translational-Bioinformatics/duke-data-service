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

shared_examples 'system_permission cannot access' do |record_sym, with_software_agent|
  let(:user) { FactoryGirl.create(:system_permission).user }
  if with_software_agent
    let(:software_agent) { FactoryGirl.create(:software_agent) }
    let(:current_software_agent_set) {
      user.current_software_agent = software_agent
      true
    }
  else
    let(:current_software_agent_set) {true}
  end
  let(:record) { send(record_sym) }

  before do
    expect(current_software_agent_set).to be_truthy
  end

  describe '.scope' do
    it { expect(resolved_scope).not_to include(record) }
  end
  permissions :show?, :create?, :update?, :destroy? do
    it { is_expected.not_to permit(user, record) }
  end
end

shared_examples 'software_agent cannot access' do |record_sym|
  let(:software_agent) { FactoryGirl.create(:software_agent) }
  let(:user) { software_agent.creator }
  let(:record) { send(record_sym) }
  let(:current_software_agent_set) {
    user.current_software_agent = software_agent
  }
  before do
    expect(current_software_agent_set).to be_truthy
  end

  describe '.scope' do
    it { expect(resolved_scope).not_to include(record) }
  end
  permissions :show?, :create?, :update?, :destroy? do
    it { is_expected.not_to permit(user, record) }
  end
end
