shared_examples 'a TrashableModel' do
  it { expect(described_class).to include(TrashableModel) }

  describe 'can_be_purged' do
    context 'when is_deleted? false' do
      it {
        expect(subject.is_deleted).to be false
        subject.is_purged = true
        is_expected.not_to be_valid
      }
    end

    context 'when is_deleted? true' do
      before do
        subject.update_column(:is_deleted, true)
      end
      it {
        expect(subject.is_deleted).to be true
        subject.is_purged = true
        is_expected.to be_valid
      }
    end
  end
end
