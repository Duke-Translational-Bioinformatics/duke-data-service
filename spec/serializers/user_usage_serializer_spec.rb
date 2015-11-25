require 'rails_helper'

RSpec.describe UserUsageSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:user) }
  let(:serializer) { UserUsageSerializer.new resource }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end

  it 'should serialize user.usage to json' do
    is_expected.to have_key('project_count')
    is_expected.to have_key('file_count')
    is_expected.to have_key('storage_bytes')
    expect(subject['project_count']).to eq(resource.project_count)
    expect(subject['file_count']).to eq(resource.file_count)
    expect(subject['storage_bytes']).to eq(resource.storage_bytes)
  end
end
