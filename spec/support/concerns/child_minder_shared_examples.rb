shared_context 'a ChildMinder' do |resource_factory, expected_children_sym|
  let(:expected_children) { send(expected_children_sym) }

  it { expect(described_class).to include(ChildMinder) }
  it { is_expected.to respond_to(:children)  }
  it { is_expected.to respond_to(:manage_children) }
  it {
    is_expected.not_to respond_to(:restore).with(0).arguments
    is_expected.to respond_to(:restore).with(1).argument
  }

  describe 'callbacks' do
    it {
      is_expected.to callback(:manage_children).after(:update)
    }
  end

  describe '#has_children?' do
    it { is_expected.to respond_to(:has_children?) }

    context 'without children' do
      subject { FactoryGirl.create(resource_factory) }
      before do
        subject.children.delete_all
      end
      it { expect(subject.children.count).to eq(0) }
      it { expect(subject.has_children?).to be_falsey }
    end

    context 'with children' do
      before do
        expect(expected_children).not_to be_empty
        expected_children.each do |child|
          expect(child).to be_persisted
          expect(child.is_deleted?).to be_falsey
        end
      end
      it { expect(subject.children.count).to be > 0 }
      it { expect(subject.has_children?).to be_truthy }
    end
  end
end
