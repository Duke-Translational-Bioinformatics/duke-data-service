require 'rails_helper'

RSpec.describe UserUsageSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:user) }
  let(:expected_attributes) {{
    'project_count' => resource.project_count,
    'file_count' => resource.file_count,
    'storage_bytes' => resource.storage_bytes
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
