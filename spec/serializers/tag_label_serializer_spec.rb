require 'rails_helper'

RSpec.describe TagLabelSerializer, type: :serializer do
  let!(:tag) { FactoryGirl.create(:tag) }
  let(:resource) { Tag.label_count.first }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('label')
      is_expected.to have_key('count')

      expect(subject['label']).to eq(resource.label)
      expect(subject['count']).to eq(resource.count)
    end
  end
end
