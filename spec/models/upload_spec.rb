require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Upload, type: :model do
  let(:project) { FactoryGirl.create(:project)}
  let(:storage_provider) { FactoryGirl.create(:storage_provider, :swift_env)}
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
end
