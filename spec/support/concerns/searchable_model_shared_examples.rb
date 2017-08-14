shared_examples 'a SearchableModel' do |resource_search_serializer_sym: :search_serializer|
  let(:resource_search_serializer) { send(resource_search_serializer_sym) }
  let(:job_transaction) { ElasticsearchIndexJob.initialize_job(subject) }

  it { expect(described_class).to include(JobTransactionable) }
  it { expect(described_class).to include(Elasticsearch::Model) }
  it { expect(described_class).not_to include(Elasticsearch::Model::Callbacks) }

  describe '#create_elasticsearch_index' do
    it { is_expected.to respond_to(:create_elasticsearch_index) }
    it {
      is_expected.to callback(:create_elasticsearch_index).after(:create)
    }
    it {
      expect(ElasticsearchIndexJob).to receive(:initialize_job).with(
        subject
      ).and_return(job_transaction)
      expect {
        subject.create_elasticsearch_index
      }.to have_enqueued_job(ElasticsearchIndexJob).with(job_transaction, subject)
    }
  end

  describe '#update_elasticsearch_index' do
    it { is_expected.to respond_to(:update_elasticsearch_index) }
    it {
      is_expected.to callback(:update_elasticsearch_index).after(:update)
    }
    it {
      expect(ElasticsearchIndexJob).to receive(:initialize_job).with(
        subject
      ).and_return(job_transaction)
      expect {
        subject.update_elasticsearch_index
      }.to have_enqueued_job(ElasticsearchIndexJob).with(job_transaction, subject, update: true)
    }
  end

  describe '#as_indexed_json' do
    it { is_expected.to respond_to('as_indexed_json').with(0).arguments }
    it { is_expected.to respond_to('as_indexed_json').with(1).argument }
    it { expect(subject.as_indexed_json).to eq(resource_search_serializer.new(subject).as_json) }
  end
end
