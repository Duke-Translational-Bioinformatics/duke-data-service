require 'rails_helper'

RSpec.describe TemplatePreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:template) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'label' => resource.label
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
