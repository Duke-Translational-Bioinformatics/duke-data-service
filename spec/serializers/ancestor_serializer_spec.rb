require 'rails_helper'

RSpec.describe AncestorSerializer, type: :serializer do
  let(:folder) { FactoryBot.create(:folder) }
  let(:project) { FactoryBot.create(:project) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'kind' => resource.kind,
    'name' => resource.name
  }}
  context 'with Folder resource' do
    let(:resource) { folder }

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'with Project resource' do
    let(:resource) { project }

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end
end
