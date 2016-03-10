require 'rails_helper'

describe DDS::V1::StorageProvidersAPI do
  include_context 'with authentication'

  let(:storage_provider) { FactoryGirl.create(:storage_provider) }
  let(:other_storage_provider) { FactoryGirl.create(:storage_provider) }
  let(:resource_class) { StorageProvider }
  let(:resource_serializer) { StorageProviderSerializer }
  let!(:resource) { storage_provider }

  describe 'Storage Providers collection' do
    let(:url) { "/api/v1/storage_providers" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        it 'should only return false or true for is_deprecated' do
          is_expected.to eq(200)
          response_json = JSON.parse(response.body)
          expect(response_json['results'].first['is_deprecated']).to_not be(nil)
          expect(response_json['results'].first['is_deprecated']).to be(false)
          expect(response.body).not_to eq('null')
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
    end
  end

  describe 'Storage Provider instance' do
    let(:url) { "/api/v1/storage_providers/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/storage_providers/notexists_id" }
      end
    end
  end
end
