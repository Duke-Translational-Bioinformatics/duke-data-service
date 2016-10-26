require 'rails_helper'

RSpec.describe DataFilePreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:data_file) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name
  }}
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
