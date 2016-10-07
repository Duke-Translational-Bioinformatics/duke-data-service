require 'rails_helper'

RSpec.describe PropertySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:property) }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'id' => resource.id,
    'key' => resource.key,
    'label' => resource.label,
    'description' => resource.description,
    'type' => resource.data_type,
    'is_deprecated' => resource.is_deprecated
  }}

  it_behaves_like 'a has_one association with', :template, TemplatePreviewSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
