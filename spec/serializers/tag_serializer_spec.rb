require 'rails_helper'

RSpec.describe TagSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:tag) }

  # it_behaves_like 'a has_many association with', :data_file, DataFileSerializer, root: :file
  it_behaves_like 'a has_one association with', :taggable, TaggableSerializer, root: :object

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('label')
      expect(subject['label']).to eq(resource.label)
    end
  end
end
