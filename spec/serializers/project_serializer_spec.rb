require 'rails_helper'

RSpec.describe ProjectSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:project) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'description' => resource.description,
    'is_deleted' => resource.is_deleted
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
