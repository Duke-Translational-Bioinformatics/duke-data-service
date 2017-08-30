shared_examples 'a TrashableModel' do
  it { expect(described_class).to include(TrashableModel) }

  describe 'can_be_purged' do
    context 'when is_deleted? false' do
      it {
        expect(subject.is_deleted).to be false
        is_expected.not_to allow_value(true).for(:is_purged)
      }
    end

    context 'when is_deleted? true' do
      before do
        subject.update_column(:is_deleted, true)
      end
      it {
        expect(subject.is_deleted).to be true
        is_expected.to allow_value(true).for(:is_purged)
      }
    end
  end
end
