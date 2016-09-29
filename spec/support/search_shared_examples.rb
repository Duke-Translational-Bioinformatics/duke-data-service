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
