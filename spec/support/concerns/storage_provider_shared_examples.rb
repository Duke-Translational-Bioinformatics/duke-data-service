shared_context 'mock all Uploads StorageProvider' do
  # use this when uploads get created by other factories, and
  # need their storage_provider mocked
  include_context 'StorageProvider Double'
  let(:mock_storage_provider_attributes) { FactoryBot.attributes_for(:storage_provider) }
  let(:mock_chunk_max_number) { mock_storage_provider_attributes[:chunk_max_number] }
  let(:mock_chunk_max_size_bytes) { mock_storage_provider_attributes[:chunk_max_size_bytes] }
  let(:mock_max_chunked_upload_size) {  mock_chunk_max_number * mock_chunk_max_size_bytes }
  let(:mock_storage_provider_id) { SecureRandom.uuid }
  let(:expected_chunk_max_exceeded) { false }
  let(:expected_endpoint) { Faker::Internet.url }

  before do
    allow_any_instance_of(Upload).to receive(:storage_provider)
      .and_return(mocked_storage_provider)
    allow(mocked_storage_provider).to receive(:max_chunked_upload_size)
      .and_return(mock_max_chunked_upload_size)
    allow(mocked_storage_provider).to receive(:chunk_max_exceeded?)
      .and_return(expected_chunk_max_exceeded)
    allow(mocked_storage_provider).to receive(:endpoint)
      .and_return(expected_endpoint)
    allow(mocked_storage_provider).to receive(:download_url) do |upload,filename=nil|
      filename ||= upload.name
      "#{Faker::Internet.url}/#{URI.encode(filename)}"
    end
    allow(mocked_storage_provider).to receive(:read_attribute_for_serialization)
     .with(:id)
     .and_return(mock_storage_provider_id)
    mock_storage_provider_attributes.keys.each do |k|
      allow(mocked_storage_provider).to receive(k.to_sym)
        .and_return(mock_storage_provider_attributes[k])

      allow(mocked_storage_provider).to receive(:read_attribute_for_serialization)
       .with(k.to_sym)
       .and_return(mock_storage_provider_attributes[k])
    end
  end
end

shared_context 'with mocked StorageProvider' do |on: []|
  # use this when the subject, or multiple objects,
  # have a storage_provider method that needs to be mocked
  include_context 'StorageProvider Double'
  let(:targets) {
    if on.empty?
      [subject]
    else
      on.map{|o|
        send(o)
      }
    end
  }

  before do
    targets.each do |target|
      allow(target).to receive(:storage_provider)
        .and_return(mocked_storage_provider)
    end
  end
end

shared_context 'StorageProvider Double' do
  let(:mocked_storage_provider) { instance_double("StorageProvider") }
end

shared_examples 'A StorageProvider' do
  it { is_expected.to be_a StorageProvider }

  it { is_expected.to respond_to(:signed_url_duration) }
  it { expect(subject.signed_url_duration).to eq 60*5 } # 5 minutes

  it { is_expected.to respond_to(:expiry) }
  it { expect(subject.expiry).to eq Time.now.to_i + subject.signed_url_duration }

  it { is_expected.to respond_to(:initialize_project).with(1).argument }
  it { is_expected.to respond_to(:single_file_upload_url).with(1).argument }
  it { is_expected.to respond_to(:initialize_chunked_upload).with(1).argument }
  it { is_expected.to respond_to(:endpoint) }
  it { is_expected.to respond_to(:chunk_max_exceeded?).with(1).argument }
  it { is_expected.to respond_to(:complete_chunked_upload).with(1).argument }
  it { is_expected.to respond_to(:chunk_upload_url).with(1).argument }
  it { is_expected.to respond_to(:max_chunked_upload_size) }
  it { is_expected.to respond_to(:suggested_minimum_chunk_size).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(2).argument }
  it { is_expected.to respond_to(:purge).with(1).argument }
end
