require 'rails_helper'

RSpec.describe TemplatePreviewSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:template) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
