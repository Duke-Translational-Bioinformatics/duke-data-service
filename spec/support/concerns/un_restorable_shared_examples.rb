shared_examples 'an UnRestorable' do
  it { expect(described_class).to include(UnRestorable) }
  it { is_expected.to respond_to :manage_deletion }
  describe 'callbacks' do
    it { is_expected.to callback(:manage_deletion).before(:update) }
  end
end

shared_examples 'an UnRestorable ChildMinder' do |resource_factory,
  expected_children_sym|
  let(:expected_children) { send(expected_children_sym) }

  it_behaves_like 'an UnRestorable'
  it_behaves_like 'a ChildMinder', resource_factory, expected_children_sym
  it { is_expected.not_to respond_to(:purge_children).with(0).arguments }
  it { is_expected.to respond_to(:purge_children).with(1).argument }
end
