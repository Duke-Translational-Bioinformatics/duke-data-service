require 'rails_helper'

RSpec.describe TagSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:tag) }
  let(:expected_attributes) {{
    'label' => resource.label,
    'audit' => Hash,
    'id' => resource.id
  }}
  it_behaves_like 'a has_one association with', :taggable, TaggableSerializer, root: :object

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
