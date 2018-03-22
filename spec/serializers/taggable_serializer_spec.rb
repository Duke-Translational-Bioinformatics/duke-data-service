require 'rails_helper'

RSpec.describe TaggableSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:data_file) }
  let(:expected_attributes) {{
    'kind' => resource.kind,
    'id' => resource.id,
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
