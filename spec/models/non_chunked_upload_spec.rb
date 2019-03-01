require 'rails_helper'

RSpec.describe NonChunkedUpload, type: :model do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:subject_storage_provider) { mocked_storage_provider }
  before(:example) do
    allow(subject).to receive(:storage_provider).and_return(subject_storage_provider)
  end

  it { is_expected.to be_an Upload }

  # Validations
  it { is_expected.to validate_numericality_of(:size)
    .is_less_than(subject.max_size_bytes)
    .with_message("File size is currently not supported - maximum size is #{subject.max_size_bytes}") }

  context 'without a storage_provider' do
    let(:subject_storage_provider) { nil }
    it { expect { is_expected.not_to validate_numericality_of(:size) }.not_to raise_error }
  end

  # Instance methods
  it { is_expected.to respond_to :max_size_bytes }
  describe '#max_size_bytes' do
    it { expect(subject.max_size_bytes).to be_a Integer }
    it { expect(subject.max_size_bytes).to eq(mocked_storage_provider.max_upload_size) }

    context 'without a storage_provider' do
      let(:subject_storage_provider) { nil }
      it { expect(subject.max_size_bytes).to be_nil }
    end
  end

  it { is_expected.to respond_to :purge_storage }
  it { is_expected.to respond_to :complete_and_validate_integrity }
end
