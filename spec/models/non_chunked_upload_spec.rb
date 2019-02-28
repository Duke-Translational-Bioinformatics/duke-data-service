require 'rails_helper'

RSpec.describe NonChunkedUpload, type: :model do
  it { is_expected.to be_an Upload }

  # Validations
  it { is_expected.to validate_numericality_of(:size)
    .is_less_than(subject.max_size_bytes)
    .with_message("File size is currently not supported - maximum size is #{subject.max_size_bytes}") }

  # Instance methods
  it { is_expected.to respond_to :max_size_bytes }
  describe '#max_size_bytes' do
    it { expect(subject.max_size_bytes).to be_a Integer }
  end

  it { is_expected.to respond_to :purge_storage }
  it { is_expected.to respond_to :complete }
  it { is_expected.to respond_to :complete_and_validate_integrity }
end
