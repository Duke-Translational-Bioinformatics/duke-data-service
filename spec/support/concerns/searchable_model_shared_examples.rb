shared_examples 'a SearchableModel' do |resource_search_serializer_sym: :search_serializer|
  let(:resource_search_serializer) { send(resource_search_serializer_sym) }
  let(:job_transaction) { ElasticsearchIndexJob.initialize_job(subject) }

  it { expect(described_class).to include(JobTransactionable) }
  it { expect(described_class).to include(Elasticsearch::Model) }
  it { expect(described_class).not_to include(Elasticsearch::Model::Callbacks) }
  it { expect(FolderFilesResponse.indexed_models).to include described_class }

  describe 'elasticsearch migrations' do
    it { expect(described_class).to respond_to(:index_name) }
    it { expect(described_class).to respond_to(:mapping_version) }
    it { expect(described_class).to respond_to(:migration_version) }
    it {
      expect(described_class).to respond_to(:versioned_index_name)
      expect(described_class.versioned_index_name).to match described_class.index_name
      expect(described_class.versioned_index_name).to match described_class.mapping_version
      expect(described_class.versioned_index_name).to match described_class.migration_version
    }
  end

  describe '#settings' do
    let(:expected_number_of_replicas) { 4 }
    let(:expected_number_of_shards) { 4 }
    let(:settings) { subject.class.settings.settings }
    let(:expected_settings) { {
      index: {
        number_of_shards: expected_number_of_shards,
        number_of_replicas: expected_number_of_replicas
      }
    }}

    before do
      @old_shards = Rails.application.config.elasticsearch_index_settings[:number_of_shards]
      @old_replicas = Rails.application.config.elasticsearch_index_settings[:number_of_replicas]
      Rails.application.config.elasticsearch_index_settings[:number_of_shards] = expected_number_of_shards
      Rails.application.config.elasticsearch_index_settings[:number_of_replicas] = expected_number_of_replicas
    end

    after do
      Rails.application.config.elasticsearch_index_settings[:number_of_shards] = @old_shards
      Rails.application.config.elasticsearch_index_settings[:number_of_replicas] = @old_replicas
    end

    it {
      expect(settings).to include(expected_settings)
    }
  end

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
      is_expected.to callback(:update_elasticsearch_index).after(:touch)
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

shared_examples 'a SearchableModel observer' do
  it {
    expect {
      resource.save
    }.to have_enqueued_job(ElasticsearchIndexJob)
  }
end
