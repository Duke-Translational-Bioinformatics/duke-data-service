shared_context 'policy declarations' do
  subject { described_class }
  let(:record_class) { 
    described_class.name.gsub(/Policy$/,'').constantize 
  }
  let(:resolved_scope) {
    described_class::Scope.new(user, record_class.all).resolve
  }
end
