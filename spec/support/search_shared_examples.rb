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
