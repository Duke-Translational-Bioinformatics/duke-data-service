require 'rails_helper'

RSpec.describe RestrictedObjectSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:folder) }
  let(:expected_attributes) {{
    'kind' => resource.kind,
    'id' => resource.id,
    'is_deleted' => resource.is_deleted
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
