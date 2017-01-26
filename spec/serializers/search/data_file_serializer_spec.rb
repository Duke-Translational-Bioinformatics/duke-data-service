require 'rails_helper'

RSpec.describe Search::DataFileSerializer, type: :serializer do
  let(:data_file) { FactoryGirl.create(:data_file, :with_parent) }
  let(:extra_searchable_attributes) {{
    'created_at' => data_file.created_at.as_json,
    'updated_at' => data_file.updated_at.as_json,
    'label' => data_file.label
  }}

  it_behaves_like 'a has_many association with', :tags, Search::TagSummarySerializer
  it_behaves_like 'a has_one association with', :creator, Search::UserSummarySerializer

  it_behaves_like 'a serialized DataFile', :data_file, with_label: true do
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(extra_searchable_attributes) }
    end

    context 'with tags' do
      include_context 'elasticsearch prep', [:tag], [:data_file]
      let(:tag) { FactoryGirl.create(:tag, taggable: data_file) }

      it_behaves_like 'a json serializer' do
        it { is_expected.to include(extra_searchable_attributes) }
        it_behaves_like 'a tagged document'
      end
    end

    context 'with meta_templates' do
      let(:meta_template) { FactoryGirl.create(:meta_template, templatable: data_file) }
      let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
      let(:meta_property){ FactoryGirl.create(:meta_property, meta_template: meta_template, property: property) }
      include_context 'elasticsearch prep', [:meta_template, :property, :meta_property], [:data_file]

      it_behaves_like 'a json serializer' do
        it { is_expected.to include(extra_searchable_attributes) }
        it_behaves_like 'a metadata annotated document'
      end
    end

    context 'with tags and meta_templates' do
      let(:tag) { FactoryGirl.create(:tag, taggable: data_file) }
      let(:meta_template) { FactoryGirl.create(:meta_template, templatable: data_file) }
      let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
      let(:meta_property){ FactoryGirl.create(:meta_property,
        meta_template: meta_template, property: property, key: property.key
      ) }
      include_context 'elasticsearch prep', [:tag, :meta_template, :property, :meta_property], [:data_file]

      it_behaves_like 'a json serializer' do
        it { is_expected.to include(extra_searchable_attributes) }
        it_behaves_like 'a tagged document'
        it_behaves_like 'a metadata annotated document'
      end
    end
  end
end
