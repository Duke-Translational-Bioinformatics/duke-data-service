require 'rails_helper'

RSpec.describe TagLabelSerializer, type: :serializer do
  let!(:tag) { FactoryGirl.create(:tag) }
  let(:resource) { Tag.tag_labels.first }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('label')
      is_expected.to have_key('count')
      is_expected.to have_key('last_used_on')

      expect(subject['label']).to eq(resource.label)
      expect(subject['count']).to eq(resource.count)
      expect(subject['last_used_on']).to eq(resource.last_used_on.as_json)
    end
  end
end
