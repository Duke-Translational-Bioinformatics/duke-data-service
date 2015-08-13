require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Upload, type: :model do
  let(:project) { FactoryGirl.create(:project)}
  let(:storage_provider) { FactoryGirl.create(:storage_provider)}
  subject { FactoryGirl.create(:upload, project_id: project.id, storage_provider_id: storage_provider.id)}

  it 'should belong_to a project' do
    should belong_to :project
  end

  it 'should belong_to a storage_provider' do
    should belong_to :storage_provider
  end

  it 'should have_many chunks' do
    should have_many :chunks
  end

  it 'should have a temporary_url method' do
    # see StorageProviderSpec get_signed_url(upload)
    should respond_to 'temporary_url'
  end

  it 'should have a create_manifest method' do
    # see StorageProviderSpec create_slo_manifest
    should respond_to 'create_manifest'
  end
end
