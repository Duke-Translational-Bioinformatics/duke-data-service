require 'rails_helper'

RSpec.describe S3StorageProvider, type: :model do
  subject { FactoryBot.build(:s3_storage_provider) }

  it_behaves_like 'A StorageProvider'
end
