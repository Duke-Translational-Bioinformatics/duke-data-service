shared_context 'elasticsearch prep' do |persisted_record_syms, refresh_record_document_syms|
  let(:persisted_records) {
    persisted_record_syms.map { |persisted_record_sym| send(persisted_record_sym) }
  }
  let(:refresh_record_documents) {
    refresh_record_document_syms.map { |refresh_record_document_sym| send(refresh_record_document_sym) }
  }

  around :each do |example|
    current_indices = DataFile.__elasticsearch__.client.cat.indices
    ElasticsearchResponse.indexed_models.each do |indexed_model|
      if current_indices.include? indexed_model.index_name
        indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
      end
      indexed_model.__elasticsearch__.client.indices.create(
        index: indexed_model.index_name,
        body: {
          settings: indexed_model.settings.to_hash,
          mappings: indexed_model.mappings.to_hash
        }
      )
    end
    Elasticsearch::Model.client.indices.flush

    refresh_record_documents.each do |refresh_record_document|
      expect(refresh_record_document).to be_persisted
      refresh_record_document.__elasticsearch__.index_document
    end

    persisted_records.each do |persisted_record|
      expect(persisted_record).to be_persisted
    end

    ElasticsearchResponse.indexed_models.each do |indexed_model|
      indexed_model.__elasticsearch__.refresh_index!
    end

    example.run

    ElasticsearchResponse.indexed_models.each do |indexed_model|
      indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
    end
  end
end

shared_examples 'a tagged document' do
  it 'should have tags with only labels and values' do
    expect(tag).to be_persisted
    resource.reload
    expect(resource.tags).to exist
    expect(resource.tags).not_to be_empty
    is_expected.to have_key 'tags'
    expect(subject['tags']).not_to be_empty
    tag_document = subject['tags']
    expect(tag_document).to be_a Array
    resource.tags.each do |tag|
      expect(tag_document).to include({"label" => tag.label})
    end
  end
end

shared_examples 'a metadata annotated document' do
  it 'should have expected meta section' do
    expect(meta_template).to be_persisted
    expect(property).to be_persisted
    expect(meta_property).to be_persisted
    resource.reload
    meta_template.reload
    meta_property.reload

    expect(resource.meta_templates).to exist
    expect(resource.meta_templates).not_to be_empty
    is_expected.to have_key 'meta'
    expect(subject['meta']).not_to be_empty
    metadata = subject['meta']
    resource.meta_templates.each do |meta_template|
      expect(meta_template.meta_properties).not_to be_empty
      expect(metadata).to have_key meta_template.template.name
      meta_template_document = metadata[meta_template.template.name]
      expect(meta_template_document).to be_a Hash
      meta_template.meta_properties.each do |prop|
        expect(meta_template_document).to have_key prop.property.key
        expect(meta_template_document[prop.property.key]).to eq(prop.value)
      end
    end
  end
end

shared_examples 'an Elasticsearch::Model' do |resource_search_serializer_sym: :search_serializer|
  let(:resource_search_serializer) { send(resource_search_serializer_sym) }
  let(:job_transaction) { ElasticsearchIndexJob.initialize_job(subject) }

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
    it { is_expected.to respond_to 'as_indexed_json' }
    it { expect(subject.as_indexed_json).to eq(resource_search_serializer.new(subject).as_json) }
  end
end

shared_examples 'an Elasticsearch index mapping model' do |expected_property_mappings_sym: :property_mappings|
  let(:expected_property_mappings) { send(expected_property_mappings_sym)}
  subject { described_class.mapping.to_hash }

  it {
    is_expected.to have_key described_class.name.underscore.to_sym

    expect(subject[described_class.name.underscore.to_sym]).to have_key :dynamic
    expect(subject[described_class.name.underscore.to_sym][:dynamic]).to eq "false"

    expect(subject[described_class.name.underscore.to_sym]).to have_key :properties
    expected_property_mappings.keys.each do |expected_property|
      expect(subject[described_class.name.underscore.to_sym][:properties]).to have_key expected_property
      expected_property_mappings[expected_property].keys.each do |expected_property_aspect|
        expect(subject[described_class.name.underscore.to_sym][:properties][expected_property][expected_property_aspect]).to eq expected_property_mappings[expected_property][expected_property_aspect]
      end
    end
  }
end

shared_examples 'an elasticsearch indexer' do
  def all_elasticsearch_documents
    expect{ elasticsearch_client.indices.flush }.not_to raise_error
    elasticsearch_client.search["hits"]["hits"]
  end

  let(:elasticsearch_client) { Elasticsearch::Model.client }
  let(:existing_documents) { elasticsearch_client.search["hits"]["hits"] }
  let(:new_documents) { all_elasticsearch_documents - existing_documents }
  before do
    expect{ existing_documents }.not_to raise_error
  end
  after do
    new_documents.each do |d|
      elasticsearch_client.delete(
        id: d["_id"],
        index: d["_index"],
        type: d["_type"]
      )
    end
  end
end

shared_context 'with a single document indexed' do
  let(:document) do
    expect(new_documents.length).to eq(1)
    expect(new_documents.first).not_to be_nil
    new_documents.first
  end
end
