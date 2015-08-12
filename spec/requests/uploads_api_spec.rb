require 'rails_helper'

describe DDS::V1::UploadsAPI do
  include_context 'with authentication'

  let(:upload) { FactoryGirl.create(:upload) }
  let(:project) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user) }
  let(:upload_stub) { FactoryGirl.build(:upload) }

  let(:resource_class) { Upload }
  let(:resource_serializer) { UploadSerializer }
  let!(:resource) { upload }

  describe 'Uploads collection' do
    let(:url) { "/api/v1/project/#{project.id}/uploads" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      #let(:project) { resource.project }

      it_behaves_like 'a listable resource'

      it_behaves_like 'an authenticated resource'
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let!(:payload) {{
        name: upload_stub.name,
        content_type: upload_stub.content_type,
        size: upload_stub.size,
        hash: {
          value: upload_stub.fingerprint_value,
          algorithm: upload_stub.fingerprint_algorithm
        }
      }}

      it_behaves_like 'a creatable resource'

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          name: nil,
          content_type: nil,
          size: nil,
          hash: {
            value: nil,
            algorithm: nil
          }
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
    end
  end

  describe 'Upload instance' do
    let(:url) { "/api/v1/uploads/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
    end
  end
end
