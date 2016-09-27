require 'rails_helper'

RSpec.describe DataFileSearchDocumentSerializer, type: :serializer do
  shared_examples 'a tagged document' do
    it 'should have tags with only labels and values' do
      expect(tag).to be_persisted
      resource.reload
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

  let(:resource) { FactoryGirl.create(:data_file) }
  let(:expected_file_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'is_deleted' => resource.is_deleted?,
    'created_at' => resource.created_at.as_json,
    'updated_at' => resource.updated_at.as_json,
    'label' => resource.label
  }}
  it_behaves_like 'a has_many association with', :tags, TagSearchDocumentSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_file_attributes) }
  end

  context 'with tags' do
    include_context 'elasticsearch prep', [:tag], [:resource]
    let(:tag) { FactoryGirl.create(:tag, taggable: resource) }

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_file_attributes) }
      it_behaves_like 'a tagged document'
    end
  end

  context 'with meta_templates' do
    let(:meta_template) { FactoryGirl.create(:meta_template, templatable: resource) }
    let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
    let(:meta_property){ FactoryGirl.create(:meta_property, meta_template: meta_template, property: property) }
    include_context 'elasticsearch prep', [:meta_template, :property, :meta_property], [:resource]

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_file_attributes) }
      it_behaves_like 'a metadata annotated document'
    end
  end

  context 'with tags and meta_templates' do
    let(:tag) { FactoryGirl.create(:tag, taggable: resource) }
    let(:meta_template) { FactoryGirl.create(:meta_template, templatable: resource) }
    let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
    let(:meta_property){ FactoryGirl.create(:meta_property,
      meta_template: meta_template, property: property, key: property.key
    ) }
    include_context 'elasticsearch prep', [:tag, :meta_template, :property, :meta_property], [:resource]

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_file_attributes) }
      it_behaves_like 'a tagged document'
      it_behaves_like 'a metadata annotated document'
    end
  end
end
