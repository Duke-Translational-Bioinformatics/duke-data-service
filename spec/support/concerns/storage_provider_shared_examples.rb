shared_context 'mocked StorageProvider Interface' do
  let(:expected_chunk_max_exceeded) { false }
  let(:expected_endpoint) { Faker::Internet.url }

  before do
    allow(mocked_storage_provider).to receive(:complete_chunked_upload)
      .and_return(true)
    allow(mocked_storage_provider).to receive(:max_chunked_upload_size)
      .and_return(
        mocked_storage_provider.chunk_max_number * mocked_storage_provider.chunk_max_size_bytes
      )
    allow(mocked_storage_provider).to receive(:chunk_max_exceeded?)
      .and_return(expected_chunk_max_exceeded)
    allow(mocked_storage_provider).to receive(:endpoint)
      .and_return(expected_endpoint)
    allow(mocked_storage_provider).to receive(:download_url) do |upload,filename=nil|
      filename ||= upload.name
      "#{expected_endpoint}/#{URI.encode(filename)}"
    end
    allow(mocked_storage_provider).to receive(:chunk_upload_url) do |chunk|
      "#{expected_endpoint}/#{chunk.sub_path}"
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

shared_examples 'A StorageProvider' do
  include ActiveSupport::Testing::TimeHelpers
  it { is_expected.to be_a StorageProvider }

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
  it { is_expected.to respond_to(:endpoint) }
  it { is_expected.to respond_to(:chunk_max_exceeded?).with(1).argument }
  it { is_expected.to respond_to(:complete_chunked_upload).with(1).argument }
  it { is_expected.to respond_to(:is_complete_chunked_upload?).with(1).argument }
  it { is_expected.to respond_to(:chunk_upload_url).with(1).argument }
  it { is_expected.to respond_to(:max_chunked_upload_size) }
  it { is_expected.to respond_to(:suggested_minimum_chunk_size).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(2).argument }
  it { is_expected.to respond_to(:purge).with(1).argument }
end
