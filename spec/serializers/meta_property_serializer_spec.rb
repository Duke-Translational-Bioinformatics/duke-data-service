require 'rails_helper'

RSpec.describe MetaPropertySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:meta_property) }
  let(:expected_attributes) {{
    'value' => resource.value
  }}

  it_behaves_like 'a has_one association with', :property, PropertyPreviewSerializer, root: :template_property

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
