shared_context 'mocked StorageProvider Interface' do
  let(:expected_chunk_max_exceeded) { false }
  let(:expected_url_root) { Faker::Internet.url }

  before do
    allow(mocked_storage_provider).to receive(:verify_upload_integrity)
      .and_return(true)
    allow(mocked_storage_provider).to receive(:complete_chunked_upload)
      .and_return(true)
    allow(mocked_storage_provider).to receive(:max_chunked_upload_size)
      .and_return(
        mocked_storage_provider.chunk_max_number * mocked_storage_provider.chunk_max_size_bytes
      )
    allow(mocked_storage_provider).to receive(:max_upload_size)
      .and_return(
        mocked_storage_provider.chunk_max_size_bytes
      )
    allow(mocked_storage_provider).to receive(:chunk_max_reached?)
      .and_return(expected_chunk_max_exceeded)
    allow(mocked_storage_provider).to receive(:url_root)
      .and_return(expected_url_root)
    allow(mocked_storage_provider).to receive(:download_url) do |upload,filename=nil|
      filename ||= upload.name
      "#{expected_url_root}/#{URI.encode(filename)}"
    end
    allow(mocked_storage_provider).to receive(:chunk_upload_ready?).and_return(true)
    allow(mocked_storage_provider).to receive(:single_file_upload_url) do |upload|
      "/#{upload.sub_path}"
    end
    allow(mocked_storage_provider).to receive(:chunk_upload_url) do |chunk|
      "#{expected_url_root}/#{chunk.sub_path}"
    end
    allow(mocked_storage_provider).to receive(:suggested_minimum_chunk_size) do |upload|
      (upload.size.to_f / mocked_storage_provider.chunk_max_number).ceil
    end
  end
end

shared_context 'mock all Uploads StorageProvider' do
  # use this when uploads get created by other factories, and
  # need their storage_provider mocked
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'

  before do
    allow_any_instance_of(Upload).to receive(:storage_provider)
      .and_return(mocked_storage_provider)
  end
end

shared_context 'mock Chunk StorageProvider' do |on: []|
  let(:targets) {
    if on.empty?
      [subject]
    else
      on.map{ |target| send(target) }
    end
  }

  before do
    expect(on).to be_a Array
    targets.each do |target|
      allow(target).to receive(:storage_provider)
        .and_return(mocked_storage_provider)
    end
  end
end

shared_context 'mocked StorageProvider' do
  let!(:mocked_storage_provider) { stub_model(StorageProvider, FactoryBot.attributes_for(:storage_provider).merge({id: SecureRandom.uuid})) }
end

shared_context 'A StorageProvider' do
  include ActiveSupport::Testing::TimeHelpers
  it { is_expected.to be_a StorageProvider }

  # Associations
  it { is_expected.to have_many(:project_storage_providers) }

  it { is_expected.to respond_to(:initialize_projects).with(0).arguments }
  it { is_expected.to callback(:initialize_projects).after(:create) }
  describe '#initialize_projects' do
    let(:project_count) { 2 }
    let(:projects) { FactoryBot.create_list(:project, project_count) }
    let!(:auth_role) { FactoryBot.create(:auth_role, :project_admin) }
    before(:example) do
      expect(subject).not_to be_persisted
      expect(projects).to all( be_persisted )
    end
    it 'creates a ProjectStorageProvider for all projects' do
      expect(subject).to receive(:initialize_projects).and_call_original
      expect { subject.save }.to change {
        ProjectStorageProvider.where(
          project: projects,
          storage_provider: subject
        ).count }.by(project_count)
    end
  end

  it { is_expected.to respond_to(:minimum_chunk_number) }

  it { is_expected.to respond_to(:fingerprint_algorithm) }
  describe '#fingerprint_algorithm' do
    it { expect(subject.fingerprint_algorithm).to eq 'md5' }
  end

  it { is_expected.to respond_to(:signed_url_duration) }
  it { expect(subject.signed_url_duration).to eq 60*5 } # 5 minutes

  it { is_expected.to respond_to(:expiry) }
  it {
    travel_to(Time.now) do #freeze_time
      expect(subject.expiry).to eq Time.now.to_i + subject.signed_url_duration
    end
  }

  it { is_expected.to respond_to(:configure) }
  it { is_expected.to respond_to(:is_ready?) }

  it { is_expected.to respond_to(:initialize_project).with(1).argument }
  it { is_expected.to respond_to(:is_initialized?).with(1).argument }
  it { is_expected.to respond_to(:single_file_upload_url).with(1).argument }
  it { is_expected.to respond_to(:initialize_chunked_upload).with(1).argument }
  it { is_expected.to respond_to(:url_root) }
  it { is_expected.to respond_to(:chunk_max_reached?).with(1).argument }
  it { is_expected.to respond_to(:verify_upload_integrity).with(1).argument }
  it { is_expected.to respond_to(:complete_chunked_upload).with(1).argument }
  it { is_expected.to respond_to(:is_complete_chunked_upload?).with(1).argument }
  it { is_expected.to respond_to(:chunk_upload_url).with(1).argument }
  it { is_expected.to respond_to(:chunk_upload_ready?).with(1).argument }
  it { is_expected.to respond_to(:max_chunked_upload_size) }
  it { is_expected.to respond_to(:max_upload_size) }
  it { is_expected.to respond_to(:suggested_minimum_chunk_size).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(2).argument }
  it { is_expected.to respond_to(:purge).with(1).argument }
end

shared_examples 'A StorageProvider implementation' do
  include_context 'A StorageProvider'

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
    it { expect { subject.initialize_project(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#is_initialized?(project)' do
    it { expect { subject.is_initialized?(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#single_file_upload_url(upload)' do
    it { expect { subject.single_file_upload_url(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#initialize_chunked_upload' do
    it { expect { subject.initialize_chunked_upload(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#chunk_max_reached?' do
    it { expect { subject.chunk_max_reached?(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#max_chunked_upload_size' do
    it { expect { subject.max_chunked_upload_size }.not_to raise_error(NotImplementedError) }
  end

  describe '#max_upload_size' do
    it { expect { subject.max_upload_size }.not_to raise_error(NotImplementedError) }
  end

  describe '#suggested_minimum_chunk_size' do
    it { expect { subject.suggested_minimum_chunk_size(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#chunk_upload_ready?(upload)' do
    it { expect { subject.chunk_upload_ready?(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#chunk_upload_url(chunk)' do
    it { expect { subject.chunk_upload_url(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#verify_upload_integrity(upload)' do
    it { expect { subject.verify_upload_integrity(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#complete_chunked_upload(upload)' do
    it { expect { subject.complete_chunked_upload(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#is_complete_chunked_upload?(upload)' do
    it { expect { subject.is_complete_chunked_upload?(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#download_url' do
    it { expect { subject.download_url(nil) }.not_to raise_error(NotImplementedError) }
  end

  describe '#purge' do
    it { expect { subject.purge(nil) }.not_to raise_error(NotImplementedError) }
  end
end
