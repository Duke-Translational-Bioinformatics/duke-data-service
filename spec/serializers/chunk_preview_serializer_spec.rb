require 'rails_helper'

RSpec.describe ChunkPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:chunk) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('number')
      is_expected.to have_key('size')
      is_expected.to have_key('hash')
      expect(subject['size']).to eq(resource.size)
      expect(subject['number']).to eq(resource.number)
      expect(subject['hash']).to eq({ 
        'value' => resource.fingerprint_value, 
        'algorithm' => resource.fingerprint_algorithm 
      })
    end
  end
end
