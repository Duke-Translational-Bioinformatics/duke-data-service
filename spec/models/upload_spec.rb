require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Upload, type: :model do
  #let(:project) { FactoryGirl.create(:project)}
  #let(:storage_provider) { FactoryGirl.create(:storage_provider)}
  subject { FactoryGirl.create(:upload)}

  describe 'associations' do
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

  describe 'validations' do
    it 'should require attributes' do
      should validate_presence_of :project_id
      should validate_presence_of :name
      should validate_presence_of :size
      should validate_presence_of :fingerprint_value
      should validate_presence_of :fingerprint_algorithm
      should validate_presence_of :storage_provider_id
    end
  end

  describe 'serialization' do
  end

  it 'should have a temporary_url method' do
    # see StorageProviderSpec get_signed_url(upload)
    is_expected.to respond_to :temporary_url
    expect(subject.temporary_url).to be_a String
  end

  it 'should have a create_manifest method' do
    # see StorageProviderSpec create_slo_manifest
    is_expected.to respond_to 'create_manifest'
  end
end
