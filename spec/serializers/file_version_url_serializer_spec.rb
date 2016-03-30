require 'rails_helper'

RSpec.describe FileVersionUrlSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:file_version) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('http_verb')
      is_expected.to have_key('host')
      is_expected.to have_key('url')
      is_expected.to have_key('http_headers')
      expect(subject['http_verb']).to eq(resource.http_verb)
      expect(subject['host']).to eq(resource.host)
      expect(subject['url']).to eq(resource.url)
      expect(subject['http_headers']).to eq([])
    end
  end
end
