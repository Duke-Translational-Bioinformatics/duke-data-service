require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Chunk, type: :model do
  let(:project) { FactoryGirl.create(:project)}
  let(:storage_provider) { FactoryGirl.create(:storage_provider, :swift_env)}
  let(:upload) { FactoryGirl.create(:upload, project_id: project.id, storage_provider_id: storage_provider.id)}
  subject { FactoryGirl.create(:chunk, upload_id: upload.id) }

  it 'should belong_to an upload' do
    should belong_to :upload
  end

  it 'should have a temporary_url method' do
    # see StorageProviderSpec get_signed_url(chunk, 'POST')
    should respond_to 'temporary_url'
  end
end
