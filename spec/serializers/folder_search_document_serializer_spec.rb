require 'rails_helper'

RSpec.describe FolderSearchDocumentSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:data_file) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'is_deleted' => resource.is_deleted?,
    'created_at' => resource.created_at.as_json,
    'updated_at' => resource.updated_at.as_json,
    'label' => resource.label
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end

  context 'with meta_templates' do
    let(:meta_template) { FactoryGirl.create(:meta_template, templatable: resource) }
    let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
    let(:meta_property){ FactoryGirl.create(:meta_property, meta_template: meta_template, property: property) }
    include_context 'elasticsearch prep', [:meta_template, :property, :meta_property], [:resource]

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
      it_behaves_like 'a metadata annotated document'
    end
  end
end
