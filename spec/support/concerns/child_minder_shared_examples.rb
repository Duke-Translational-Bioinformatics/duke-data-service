shared_context 'a ChildMinder' do |resource_factory,
  valid_child_file_sym,
  invalid_child_file_sym,
  child_folder_sym|
  let(:valid_child_file) { send(valid_child_file_sym) }
  let(:invalid_child_file) { send(invalid_child_file_sym) }
  let(:child_folder) { send(child_folder_sym) }

  it {
    expect(described_class).to include(ChildMinder)
    is_expected.to respond_to(:children)
  }

  it {
    is_expected.to respond_to(:manage_children)
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
      it { expect(subject.children.count).to eq(0) }
      it { expect(subject.has_children?).to be_falsey }
    end

    context 'with children' do
      before do
        expect(child_folder).to be_persisted
        expect(child_folder.is_deleted?).to be_falsey
        expect(valid_child_file).to be_persisted
        expect(valid_child_file.is_deleted?).to be_falsey
        expect(invalid_child_file).to be_persisted
        expect(invalid_child_file.is_deleted?).to be_falsey
      end
      it { expect(subject.children.count).to be > 0 }
      it { expect(subject.has_children?).to be_truthy }
    end
  end
end
