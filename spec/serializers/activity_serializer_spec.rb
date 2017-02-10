require 'rails_helper'
RSpec.describe ActivitySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:activity,
    started_on: 10.minutes.ago,
    ended_on: DateTime.now
  ) }
  let(:expected_attributes) {{
      'id' => resource.id,
      'name' => resource.name,
      'description' => resource.description,
      'started_on' => resource.started_on.as_json,
      'ended_on' => resource.ended_on.as_json,
      'is_deleted' => resource.is_deleted
    }}
  let(:is_logically_deleted) { true }

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
