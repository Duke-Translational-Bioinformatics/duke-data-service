require 'rails_helper'

RSpec.describe DataFilePreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:data_file) }

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('name')
      expect(subject['id']).to eq(resource.id)
      expect(subject['name']).to eq(resource.name)
    end
  end
end
