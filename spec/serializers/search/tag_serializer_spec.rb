require 'rails_helper'

RSpec.describe Search::TagSerializer, type: :serializer do
  let(:tagged_file) { FactoryGirl.create(:data_file) }
  let(:resource) { FactoryGirl.create(:tag, taggable: tagged_file) }

  let(:expected_attributes) {{
    'label' => resource.label
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to eq(expected_attributes) }
  end
end
