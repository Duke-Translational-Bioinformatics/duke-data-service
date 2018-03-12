require 'rails_helper'

RSpec.describe MetaPropertySerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:meta_property) }
  let(:meta_template) { resource.meta_template }
  let(:templatable) { meta_template.templatable }
  let(:property) { resource.property }

  include_context 'elasticsearch prep', [
      :meta_template,
      :property
    ],
    [:templatable]

  let(:expected_attributes) {{
    'value' => resource.value
  }}

  it_behaves_like 'a has_one association with', :property, PropertyPreviewSerializer, root: :template_property

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
