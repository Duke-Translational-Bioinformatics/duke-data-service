require 'rails_helper'

RSpec.describe TemplatableSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:data_file) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'kind' => resource.kind,
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
