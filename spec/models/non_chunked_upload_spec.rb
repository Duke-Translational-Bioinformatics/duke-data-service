require 'rails_helper'

RSpec.describe NonChunkedUpload, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:subject_storage_provider) { mocked_storage_provider }
  let(:unexpected_exception) { StorageProviderException.new('Unexpected') }
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

  it { is_expected.to respond_to :single_file_upload_url }
  describe '#single_file_upload_url' do
    subject { FactoryBot.create(:non_chunked_upload, storage_provider: subject_storage_provider) }
    let(:sp_response) { '/' + Faker::Internet.user_name }
    before(:example) do
      allow(subject_storage_provider).to receive(:single_file_upload_url)
        .with(subject) { sp_response }
    end
    it { expect(subject.single_file_upload_url).to eq(sp_response) }
  end

  it { is_expected.to respond_to :signed_url }
  describe '#signed_url' do
    subject { FactoryBot.create(:non_chunked_upload, storage_provider: subject_storage_provider) }
    let(:expected_url) { '/' + Faker::Internet.user_name }
    let(:signed_url_hash) { {
      http_verb: "PUT",
      host: subject_storage_provider.url_root,
      url: expected_url,
      http_headers: []
    } }
    before(:example) { is_expected.to receive(:single_file_upload_url) { expected_url } }
    it { expect(subject.signed_url).to eq(signed_url_hash) }
  end

  it { is_expected.to respond_to :purge_storage }
  describe '#purge_storage' do
    subject { FactoryBot.create(:non_chunked_upload, storage_provider: subject_storage_provider) }
    let(:sp_purge_response) { true }
    let(:now) { Time.now }

    around(:each) do |example|
      travel_to(now) do #freeze_time
        example.run
      end
    end
    before(:example) do
      expect(mocked_storage_provider).to receive(:purge)
        .with(subject) { sp_purge_response }
      expect(subject.purged_on).to be_nil
    end

    it 'update #purged_on to now' do
      expect { subject.purge_storage }.not_to raise_error
      expect(subject.reload).to be_truthy
      expect(subject.purged_on.to_i).to eq now.to_i
    end

    context 'when storage_provider raises exception' do
      let(:sp_purge_response) { raise unexpected_exception }
      it 'does not update #purged_on and raises exception' do
        expect { subject.purge_storage }.to raise_error(unexpected_exception)
        expect(subject.reload).to be_truthy
        expect(subject.purged_on).to be_nil
      end
    end
  end

  it { is_expected.to respond_to :complete_and_validate_integrity }
  describe '#complete_and_validate_integrity' do
    subject { FactoryBot.create(:non_chunked_upload, is_consistent: false, storage_provider: subject_storage_provider) }
    let(:vui_response) { true }

    before(:example) do
      expect(mocked_storage_provider).to receive(:verify_upload_integrity).with(subject) { vui_response }
      expect(subject.is_consistent).to be_falsey
    end

    context 'with verified upload' do
      before(:example) do
        expect { subject.complete_and_validate_integrity }.not_to raise_error
        expect(subject.reload).to be_truthy
      end
      it { expect(subject.is_consistent).to be_truthy }
      it { expect(subject.error_at).to be_nil }
      it { expect(subject.error_message).to be_nil }
    end

    context 'with IntegrityException' do
      let(:vui_response) { raise IntegrityException, exception_message }
      let(:exception_message) { Faker::Hacker.say_something_smart }
      let(:now) { Time.now }

      around(:each) do |example|
        travel_to(now) do #freeze_time
          example.run
        end
      end
      before(:example) do
        expect { subject.complete_and_validate_integrity }.not_to raise_error
        expect(subject.reload).to be_truthy
      end
      it { expect(subject.is_consistent).to be_truthy }
      it { expect(subject.error_at.to_i).to eq now.to_i }
      it { expect(subject.error_message).to include(exception_message) }
    end

    context 'with StorageProviderException' do
      let(:vui_response) { raise unexpected_exception }
      before(:example) do
        expect { subject.complete_and_validate_integrity }.to raise_error unexpected_exception
        expect(subject.reload).to be_truthy
      end
      it { expect(subject.is_consistent).to be_falsey }
      it { expect(subject.error_at).to be_nil }
      it { expect(subject.error_message).to be_nil }
    end
  end
end
