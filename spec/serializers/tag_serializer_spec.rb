require 'rails_helper'

RSpec.describe TagSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:tagged_file) }

  it_behaves_like 'a has_one association with', :taggable, TaggableSerializer, root: :object

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('label')
      is_expected.to have_key('audit')
      is_expected.to have_key('id')

      expect(subject['label']).to eq(resource.label)
      expect(subject['audit']).to be_a Hash
      expect(subject['id']).to eq(resource.id)
    end
  end
end
