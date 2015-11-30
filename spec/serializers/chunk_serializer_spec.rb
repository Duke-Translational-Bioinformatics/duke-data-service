require 'rails_helper'

RSpec.describe ChunkSerializer, type: :serializer, :vcr => {:match_requests_on => [:method, :uri_ignoring_uuids]} do
  let(:resource) { FactoryGirl.create(:chunk, :swift) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('http_verb')
      is_expected.to have_key('host')
      is_expected.to have_key('url')
      is_expected.to have_key('http_headers')
      expect(subject['http_verb']).to eq(resource.http_verb)
      expect(subject['host']).to eq(resource.host)
      expect(subject['http_headers']).to eq(resource.http_headers)
      expect(subject['url']).to eq(resource.url)
    end
  end
end
