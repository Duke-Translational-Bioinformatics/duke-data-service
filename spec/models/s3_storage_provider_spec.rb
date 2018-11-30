require 'rails_helper'

RSpec.describe S3StorageProvider, type: :model do
  subject { FactoryBot.build(:s3_storage_provider) }
  let(:project) { stub_model(Project, id: SecureRandom.uuid) }
  let(:upload) { FactoryBot.create(:upload, :skip_validation) }
  let(:chunk) { FactoryBot.create(:chunk, :skip_validation, upload: upload) }

  it_behaves_like 'A StorageProvider implementation'
end
