shared_context 'with mocked StorageProvider' do
  let(:storage_provider) { instance_double("StorageProvider") }

  before do
    allow(subject).to receive(:storage_provider)
      .and_return(storage_provider)
  end
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
  it { is_expected.to respond_to(:complete_chunked_upload).with(1).argument }
  it { is_expected.to respond_to(:chunk_upload_url).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(1).argument }
  it { is_expected.to respond_to(:download_url).with(2).argument }
  it { is_expected.to respond_to(:purge).with(1).argument }
end
