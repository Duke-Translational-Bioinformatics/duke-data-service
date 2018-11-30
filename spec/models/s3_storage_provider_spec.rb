require 'rails_helper'

RSpec.describe S3StorageProvider, type: :model do
  subject { FactoryBot.build(:s3_storage_provider) }
  let(:project) { stub_model(Project, id: SecureRandom.uuid) }
  let(:upload) { FactoryBot.create(:upload, :skip_validation) }
  let(:chunk) { FactoryBot.create(:chunk, :skip_validation, upload: upload) }

  it_behaves_like 'A StorageProvider'

  around(:example) do |example|
    false_positive_config = RSpec::Expectations.configuration.on_potential_false_positives
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing
    example.run
    RSpec::Expectations.configuration.on_potential_false_positives = false_positive_config
  end
  describe '#configure' do
    it { expect { subject.configure }.not_to raise_error(NotImplementedError) }
  end

  describe '#is_ready?' do
    it { expect { subject.is_ready? }.not_to raise_error(NotImplementedError) }
  end

  describe '#initialize_project' do
    it { expect { subject.initialize_project(project) }.not_to raise_error(NotImplementedError) }
  end

  describe '#is_initialized?(project)' do
    it { expect { subject.is_initialized?(project) }.not_to raise_error(NotImplementedError) }
  end

  describe '#initialize_chunked_upload' do
    it { expect { subject.initialize_chunked_upload(upload) }.not_to raise_error(NotImplementedError) }
  end

  describe '#endpoint' do
    it { expect { subject.endpoint }.not_to raise_error(NotImplementedError) }
  end

  describe '#chunk_max_reached?' do
    it { expect { subject.chunk_max_reached?(chunk) }.not_to raise_error(NotImplementedError) }
  end

  describe '#max_chunked_upload_size' do
    it { expect { subject.max_chunked_upload_size }.not_to raise_error(NotImplementedError) }
  end

  describe '#suggested_minimum_chunk_size' do
    it { expect { subject.suggested_minimum_chunk_size(upload) }.not_to raise_error(NotImplementedError) }
  end

  describe '#chunk_upload_url(chunk)' do
    it { expect { subject.chunk_upload_url(chunk) }.not_to raise_error(NotImplementedError) }
  end

  describe '#download_url' do
    it { expect { subject.download_url(upload) }.not_to raise_error(NotImplementedError) }
  end

  describe '#purge' do
    it { expect { subject.purge(upload) }.not_to raise_error(NotImplementedError) }
    it { expect { subject.purge(chunk) }.not_to raise_error(NotImplementedError) }
  end
end
