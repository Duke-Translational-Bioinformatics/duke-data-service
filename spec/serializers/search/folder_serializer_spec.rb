require 'rails_helper'

RSpec.describe Search::FolderSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:folder) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'is_deleted' => resource.is_deleted?,
    'created_at' => resource.created_at.as_json,
    'updated_at' => resource.updated_at.as_json,
    'label' => resource.label
  }}

  it_behaves_like 'a has_one association with', :parent, Search::FolderSummarySerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
