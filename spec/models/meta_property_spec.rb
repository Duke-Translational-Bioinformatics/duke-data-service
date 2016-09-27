require 'rails_helper'

RSpec.describe MetaProperty, type: :model do
  let(:templatable) { FactoryGirl.create(:data_file) }
  let(:meta_template) { FactoryGirl.create(:meta_template, templatable: templatable) }
  let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
  let(:other_property) { FactoryGirl.create(:property) }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:meta_template) }
    it { is_expected.to belong_to(:property) }
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_property_from_key).before(:validation) }
    it { is_expected.to callback(:create_mapping).before(:create) }
  end

  describe 'validations' do
    include_context 'elasticsearch prep', [
        :meta_template,
        :property,
        :existing_meta_property_for_uniqueness_validation
      ],
      [:templatable]
    let(:existing_meta_property_for_uniqueness_validation) { FactoryGirl.create(:meta_property, meta_template: meta_template) }

    it { is_expected.to validate_presence_of(:meta_template) }
    it { is_expected.to validate_presence_of(:property) }
    it { is_expected.to validate_presence_of(:value) }

    it { is_expected.to validate_uniqueness_of(:property).scoped_to(:meta_template_id).case_insensitive }

    context 'when a meta_template is set' do
      subject { FactoryGirl.build(:meta_property, meta_template: meta_template) }

      it { is_expected.to allow_value(nil).for(:key) }
      it { is_expected.to allow_value(property.key).for(:key) }
      it { is_expected.not_to allow_value(other_property.key).for(:key) }
    end

    context 'when a meta_template is nil' do
      subject { FactoryGirl.build(:meta_property, meta_template: nil) }

      it { is_expected.to allow_value(nil).for(:key) }
      it { is_expected.not_to allow_value(property.key).for(:key) }
      it { is_expected.not_to allow_value(other_property.key).for(:key) }
    end
  end

  it { is_expected.to respond_to(:key) }
  it { is_expected.to respond_to(:key=).with(1).argument }

  describe '#set_property_from_key' do
    it { is_expected.to respond_to(:set_property_from_key) }

    context 'called' do
      before { expect{subject.set_property_from_key}.not_to raise_error }

      context 'when key is nil' do
        subject { FactoryGirl.build(:meta_property, meta_template: meta_template, property: property, key: nil) }

        it { expect(subject.key).to be_nil }
        it { expect(subject.property).to eq(property) }
      end

      context 'when meta_template is nil' do
        subject { FactoryGirl.build(:meta_property, meta_template: nil, key: property.key) }

        it { expect(subject.key).to eq(property.key) }
        it { expect(subject.meta_template).to be_nil }
        it { expect(subject.property).to be_nil }
      end

      context 'when key is a property from another template' do
        subject { FactoryGirl.build(:meta_property, meta_template: meta_template, key: other_property.key) }

        it { expect(subject.key).to eq(other_property.key) }
        it { expect(subject.meta_template).to eq(meta_template) }
        it { expect(subject.property).to be_nil }
      end

      context 'when key is a property from the assigned template' do
        subject { FactoryGirl.build(:meta_property, meta_template: meta_template, key: property.key) }

        it { expect(subject.key).to eq(property.key) }
        it { expect(subject.meta_template).to eq(meta_template) }
        it { expect(subject.property).to eq(property) }
      end
    end
  end

  describe 'search' do
    include_context 'elasticsearch prep', [:meta_template, :property], [:templatable]
    subject { FactoryGirl.build(:meta_property, meta_template: meta_template, key: property.key, value: property_value) }
    let(:property_value) { 'tosearch' }
    let(:index_name) { meta_template.templatable.class.index_name }
    let(:index_type) { meta_template.templatable.class.name.underscore }
    let(:query) {
      {query: {
        match: {
          "meta.#{meta_template.template.name}.#{property.key}" => property_value
        }
      }}
    }

    context 'mapping_exists?' do
      it {
        is_expected.to respond_to 'mapping_exists?'
      }
    end

    context 'create_mapping' do
      it {
        current_mappings = Elasticsearch::Model.client.indices.get_mapping index: index_name
        expect(current_mappings[index_name]["mappings"]).to have_key index_type
        if current_mappings[index_name]["mappings"][index_type]["properties"].has_key? "meta"
          if current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"].has_key meta_template.template.name
            expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"]).not_to have_key property.key
          end
        end
        expect(subject.mapping_exists?).not_to be true

        is_expected.to be_valid
        subject.create_mapping
        current_mappings = Elasticsearch::Model.client.indices.get_mapping index: index_name
        expect(current_mappings[index_name]["mappings"][index_type]["properties"]).to have_key "meta"
        expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"]).to have_key meta_template.template.name
        expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"]).to have_key property.key
        expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"][property.key]["type"]).to eq property.data_type
        if property.data_type == "string"
          expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"][property.key]).to have_key "fields"
          expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"][property.key]["fields"]).to have_key "raw"
          expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"][property.key]["fields"]["raw"]["type"]).to eq "string"
          expect(current_mappings[index_name]["mappings"][index_type]["properties"]["meta"]["properties"][meta_template.template.name]["properties"][property.key]["fields"]["raw"]["index"]).to eq "not_analyzed"
        end
        expect(subject.mapping_exists?).to be true
      }
    end

    context 'after save' do
      it {
        expect(meta_template.templatable.class.__elasticsearch__.search(query).count).to eq 0
        subject.save
        meta_template.templatable.class.__elasticsearch__.client.indices.flush
        search = meta_template.templatable.class.__elasticsearch__.search(query)
        expect(search.count).to eq 1
        expect(search.results.first.id).to eq(meta_template.templatable.id)
      }
    end

    context 'after destroy' do
      it {
        subject.save
        meta_template.templatable.class.__elasticsearch__.client.indices.flush
        search = meta_template.templatable.class.__elasticsearch__.search(query)
        expect(search.count).to eq 1
        expect(search.results.first.id).to eq(meta_template.templatable.id)
        subject.destroy
        meta_template.templatable.class.__elasticsearch__.client.indices.flush
        search = meta_template.templatable.class.__elasticsearch__.search(query)
        expect(search.count).to eq 0
      }
    end
  end
end
