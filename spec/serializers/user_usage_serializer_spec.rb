require 'rails_helper'

RSpec.describe UserUsageSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:user) }

  it_behaves_like 'a json serializer' do
    it 'should serialize user.usage to json' do
      is_expected.to have_key('project_count')
      is_expected.to have_key('file_count')
      is_expected.to have_key('storage_bytes')
      expect(subject['project_count']).to eq(resource.project_count)
      expect(subject['file_count']).to eq(resource.file_count)
      expect(subject['storage_bytes']).to eq(resource.storage_bytes)
    end
  end
end
