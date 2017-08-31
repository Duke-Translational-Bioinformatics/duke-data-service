shared_examples 'a TrashableModel' do
  it { expect(described_class).to include(TrashableModel) }

  describe 'validations' do
    before {
      subject.update_columns(is_deleted: true, is_purged: true)
    }
    it 'expects is_deleted and is_purged to be immutable once purged' do
      is_expected.to be_persisted
      expect(subject.is_deleted?).to be_truthy
      expect(subject.is_purged?).to be_truthy
      [:is_deleted, :is_purged].each do |immutable_field|
        is_expected.not_to allow_value(false).for(immutable_field)
      end
    end
  end

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
