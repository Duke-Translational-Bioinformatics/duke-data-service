RSpec.describe FolderSearchDocumentSerializer, type: :serializer do
  shared_examples 'a tagged document' do
    it 'should have tags with only labes and values' do
      expect(resource.tags).to exist
      is_expected.to have_key 'tags'
      expect(subject['tags']).not_to be_empty
      tag_document = subject['tags']
      expect(tag_document).to be_a Array
      resource.tags.each do |tag|
        expect(tag_document).to include({label: tag.label})
      end
    end
  end

  shared_examples 'a metadata annotated document' do
    it 'should have expected metadata section' do
      expect(resource.meta_templates).to exist
      is_expected.to have_key 'metadata'
      expect(subject['metadata']).not_to be_empty
      metadata = subject['metadata']
      resource.meta_templates.each do |meta_template|
        expect(meta_template.meta_properties).to exist
        expect(metadata).to have_key meta_template.name
        meta_template_document = metadata[meta_template.name]
        expect(meta_template_document).to be_a Hash
        meta_template.meta_properties.each do |prop|
          expect(meta_template_document).to have_key prop.key
          expect(meta_template_document[prop.key]).to eq(prop.value)
        end
      end
    end
  end

  let(:resource) { FactoryGirl.create(:data_file) }
  let(:expected_file_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'is_deleted' => resource.is_deleted?,
    'created_at' => resource.created_at.as_json,
    'updated_at' => resource.updated_at.as_json,
    'label' => resource.label
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_file_attributes) }
  end
end
