require 'rails_helper'

RSpec.describe TagLabelSerializer, type: :serializer do
  let!(:tag) { FactoryBot.create(:tag) }
  let(:resource) { Tag.tag_labels.first }
  let(:expected_attributes) {{
    'label' => resource.label,
    'count' => resource.count,
    'last_used_on' => resource.last_used_on.as_json
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
