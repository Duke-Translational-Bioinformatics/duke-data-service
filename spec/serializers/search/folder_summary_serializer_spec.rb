require 'rails_helper'

RSpec.describe Search::FolderSummarySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:folder) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
