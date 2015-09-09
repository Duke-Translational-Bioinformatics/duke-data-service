require 'rails_helper'

RSpec.describe Upload, type: :model do
  subject { FactoryGirl.create(:upload, :with_chunks) }
  let(:expected_sub_path) { [subject.project_id, subject.id].join('/')}

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

  describe 'instance methods' do
    it 'should have a sub_path method' do
      should respond_to :sub_path
      expect(subject.sub_path).to eq expected_sub_path
    end

    it 'should have a temporary_url method' do
      is_expected.to respond_to :temporary_url
      expect(subject.temporary_url).to be_a String
    end

    it 'should have a completed_at attribute' do
      is_expected.to respond_to 'completed_at'
      is_expected.to respond_to 'completed_at='
    end

    it 'should have a manifest method' do
      is_expected.to respond_to 'manifest'
      expect(subject.manifest).to be_a Array
      expect(subject.chunks).not_to be_empty
      expect(subject.manifest.count).to eq(subject.chunks.count)
      subject.chunks.each do |chunk|
        chunk_manifest = {
          path: chunk.sub_path, 
          etag: chunk.fingerprint_value,
          size_bytes: chunk.size
        }
        expect(subject.manifest).to include chunk_manifest
      end
    end
  end

  describe 'swift methods' do
    subject { FactoryGirl.create(:upload, :swift, :with_chunks) }

    let(:complete) { subject.complete }
    it 'should have a complete method', :vcr => {:match_requests_on => [:method, :uri_ignoring_uuids]} do
      is_expected.to respond_to 'complete'
      expect { complete }.not_to raise_error
      expect(complete).to be_truthy
    end
  end

  describe 'serialization' do
  end
end
