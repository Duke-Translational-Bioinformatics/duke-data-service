require 'rails_helper'

RSpec.describe SoftwareAgentSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:software_agent) }
  let(:is_logically_deleted) { true }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('name')
      is_expected.to have_key('description')
      is_expected.to have_key('repo_url')
      is_expected.to have_key('is_deleted')
      is_expected.to have_key('audit')

      expect(subject['id']).to eq(resource.id)
      expect(subject['name']).to eq(resource.name)
      expect(subject['description']).to eq(resource.description)
      expect(subject['repo_url']).to eq(resource.repo_url)
      expect(subject['is_deleted']).to eq(resource.is_deleted)
      expect(subject['audit']).to be_a Hash
    end
    it_behaves_like 'a serializer with a serialized audit'
  end
end
