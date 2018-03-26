require 'rails_helper'

RSpec.describe TemplateSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:template) }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'label' => resource.label,
    'description' => resource.description,
    'is_deprecated' => resource.is_deprecated
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
