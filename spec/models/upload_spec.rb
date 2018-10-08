require 'rails_helper'

RSpec.describe Upload, type: :model do
  subject { FactoryBot.create(:upload, :swift, :with_chunks) }
  let(:fingerprint) { FactoryBot.create(:fingerprint, upload: subject) }
  let(:completed_upload) { FactoryBot.create(:upload, :swift, :with_chunks, :with_fingerprint, :completed) }
  let(:upload_with_error) { FactoryBot.create(:upload, :swift, :with_chunks, :with_error) }
  let(:expected_object_path) { subject.id }
  let(:expected_sub_path) { [subject.storage_container, expected_object_path].join('/')}

  it_behaves_like 'an audited model'
  it_behaves_like 'a job_transactionable model'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:storage_provider) }
    it { is_expected.to have_many(:chunks) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:fingerprints) }
  end

  it { is_expected.to accept_nested_attributes_for(:fingerprints) }

  describe 'validations' do
    it { is_expected.to validate_presence_of :project_id }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :size }
    it {
      is_expected.to validate_numericality_of(:size)
      .is_less_than(subject.max_size_bytes)
      .with_message("File size is currently not supported - maximum size is #{subject.max_size_bytes}")
    }
    it { is_expected.to validate_presence_of :storage_provider_id }
    it { is_expected.to validate_presence_of :creator_id }

    it { is_expected.not_to validate_presence_of :fingerprint_value }
    it { is_expected.not_to validate_presence_of :fingerprint_algorithm }

    it { is_expected.to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    it { is_expected.not_to validate_presence_of :fingerprints }

    context 'when completed_at is set' do
      before { subject.completed_at = Faker::Time.forward(1) }
      it { is_expected.to validate_presence_of :fingerprints }
    end

    context 'when completed_at is nil' do
      it { is_expected.not_to be_completed_at }
      it { is_expected.not_to allow_value([fingerprint]).for(:fingerprints) }
    end

    context 'completed upload' do
      subject { completed_upload }
      it { is_expected.not_to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    end

    context 'upload with error' do
      subject { upload_with_error }
      it { is_expected.not_to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    end

    it 'expects storage_container to be immutable' do
      is_expected.to be_persisted
      is_expected.to allow_value(subject.project_id).for(:storage_container)
      is_expected.to allow_value(subject.storage_container).for(:storage_container)
      is_expected.not_to allow_value('a-different-string').for(:storage_container)
        .with_message("Cannot change storage_container.")
    end
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_storage_container).before(:create) }
  end

  describe 'instance methods' do
    it { should delegate_method(:url_root).to(:storage_provider) }

    it 'should have a http_verb method' do
      should respond_to :http_verb
      expect(subject.http_verb).to eq 'GET'
    end

    it 'should have a sub_path method' do
      should respond_to :sub_path
      expect(subject.sub_path).to eq expected_sub_path
    end

    it 'should have an object_path method' do
      should respond_to :object_path
      expect(subject.object_path).to eq(expected_object_path)
    end

    describe '#temporary_url' do
      it { is_expected.to respond_to :temporary_url }
      it { expect(subject.temporary_url).to be_a String }
      it { expect(subject.temporary_url).to include subject.name }
      it { expect(subject.temporary_url).to include subject.storage_container }

      context 'when filename is provided' do
        let(:filename) { 'different-file-name.txt' }
        it { expect(subject.temporary_url(filename)).to include filename }
      end

      context 'when has_integrity_exception? true' do
        it {
          expect(subject).to receive(:has_integrity_exception?).and_return(true)
          expect {
            subject.temporary_url
          }.to raise_error(IntegrityException)
        }
      end

      context 'when not consistent' do
        before do
          expect(subject.update(is_consistent: false)).to be_truthy
        end
        it {
          expect(subject.is_consistent?).to be_falsey
          expect {
            subject.temporary_url
          }.to raise_error(ConsistencyException)
        }
      end
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
      subject.chunks.reorder(:number).each do |chunk|
        chunk_manifest = {
          path: chunk.sub_path,
          etag: chunk.fingerprint_value,
          size_bytes: chunk.size
        }
        expect(subject.manifest[chunk.number - 1]).to eq chunk_manifest
      end
    end
  end

  describe '#complete' do
    let(:fingerprint_attributes) { FactoryBot.attributes_for(:fingerprint) }
    before { subject.fingerprints_attributes = [fingerprint_attributes] }

    it { is_expected.to respond_to :complete }
    it {
      expect(subject.completed_at).to be_nil
      expect {
        expect(subject.complete).to be_truthy
      }.to have_enqueued_job(UploadCompletionJob)
      subject.reload
      expect(subject.completed_at).not_to be_nil
    }
  end

  describe '#has_integrity_exception?' do
    it { is_expected.to respond_to :has_integrity_exception? }

    context 'when upload is_consistent and has an error' do
      it {
        exactly_now = DateTime.now
        expect(
          subject.update({
            error_at: exactly_now,
            error_message: 'integrity exception',
            is_consistent: true
          })
        ).to be_truthy
        expect(subject.has_integrity_exception?).to be_truthy
      }
    end

    context 'when upload is_consistent and does not have an error' do
      it {
        exactly_now = DateTime.now
        expect(
          subject.update({
            is_consistent: true
          })
        ).to be_truthy
        expect(subject.has_integrity_exception?).to be_falsey
      }
    end
  end

  describe '#set_storage_container' do
    it { is_expected.to respond_to :set_storage_container }

    context 'upload creation' do
      subject { FactoryBot.build(:upload) }
      it {
        expect(subject.storage_container).to be_nil
        subject.save
        expect(subject.storage_container).to eq(subject.project_id)
      }
    end

    context 'upload update' do
      subject { FactoryBot.create(:upload) }
      let(:original_storage_container) { subject.storage_container }
      let(:other_project) { completed_upload.project }

      it {
        expect(subject.storage_container).to eq(subject.project_id)
        expect(subject.storage_container).to eq(original_storage_container)
        subject.project = other_project
        subject.save
        expect(subject.storage_container).not_to eq(other_project.id)
        expect(subject.storage_container).to eq(original_storage_container)
      }
    end
  end

  describe '#max_size_bytes' do
    let(:expected_max_size_bytes) { subject.storage_provider.chunk_max_number * subject.storage_provider.chunk_max_size_bytes }
    it { is_expected.to respond_to :max_size_bytes }
    it { expect(subject.max_size_bytes).to eq(expected_max_size_bytes) }
  end

  describe '#minimum_chunk_size' do
    let(:storage_provider) { FactoryBot.create(:storage_provider) }
    let(:size) { storage_provider.chunk_max_number }
    subject { FactoryBot.create(:upload, storage_provider: storage_provider, size: size) }
    let(:expected_minimum_chunk_size) {
      (subject.size.to_f / subject.storage_provider.chunk_max_number).ceil
    }

    it { is_expected.to respond_to :minimum_chunk_size }

    context 'size = 0' do
      let(:size) { 0 }
      it { expect(subject.minimum_chunk_size).to eq(expected_minimum_chunk_size) }
    end

    context 'size < storage_provider.chunk_max_number' do
      let(:size) { storage_provider.chunk_max_number - 1 }
      it { expect(subject.minimum_chunk_size).to eq(expected_minimum_chunk_size) }
    end

    context 'size > storage_provider.chunk_max_number' do
      let(:size) { storage_provider.chunk_max_number + 1 }
      it { expect(subject.minimum_chunk_size).to eq(expected_minimum_chunk_size) }
    end
  end

  describe 'swift methods', :vcr do
    subject { FactoryBot.create(:upload, :swift, :with_chunks) }

    before do
      actual_size = 0
      subject.storage_provider.put_container(subject.storage_container)
      subject.chunks.each do |chunk|
        body = 'this is a chunk'
        subject.storage_provider.put_object(
          subject.storage_container,
          chunk.object_path,
          body
        )
        chunk.update_attributes({
          fingerprint_value: Digest::MD5.hexdigest(body),
          size: body.length
        })
        actual_size = body.length + actual_size
      end
      subject.update_attribute(:size, actual_size)
    end

    after do
      begin
        subject.chunks.each do |chunk|
          object = [subject.id, chunk.number].join('/')
          subject.storage_provider.delete_object(subject.storage_container, object)
        end
        subject.storage_provider.delete_object_manifest(subject.storage_provider, subject.id)
      rescue
        # ignore
      end
    end

    describe '#create_and_validate_storage_manifest' do
      it { is_expected.to respond_to :create_and_validate_storage_manifest }

      describe 'calls' do
        describe 'with valid reported size and chunk hashes' do
          it 'should set is_consistent to true, leave error_at and error_message null' do
            subject.create_and_validate_storage_manifest
            subject.reload
            expect(subject.is_consistent).to be_truthy
            expect(subject.error_at).to be_nil
            expect(subject.error_message).to be_nil
          end
        end #with valid

        describe 'with reported size not equal to swift computed size' do
          it 'should set is_consistent to true, set integrity_exception message as error_message, and set error_at' do
            subject.update_attribute(:size, subject.size - 1)
            subject.create_and_validate_storage_manifest
            subject.reload
            expect(subject.is_consistent).to be_truthy
            expect(subject.error_at).not_to be_nil
            expect(subject.error_message).not_to be_nil
          end
        end #with reported size

        describe 'with reported chunk hash not equal to swift computed chunk etag' do
          it 'should update completed_at, error_at and error_message and raise an IntegrityException' do
            bad_chunk = subject.chunks.first
            bad_chunk.update_attribute(:fingerprint_value, "NOTTHECOMPUTEDHASH")
            subject.create_and_validate_storage_manifest
            subject.reload
            expect(subject.is_consistent).to be_truthy
            expect(subject.error_at).not_to be_nil
            expect(subject.error_message).not_to be_nil
          end
        end #with reported chunk
      end #calls
    end #complete

    context '#purge_storage' do
      it { is_expected.to respond_to :purge_storage }

      context 'calls' do
        before do
          subject.create_and_validate_storage_manifest
        end

        context 'with StorageProviderException' do
          context 'Object Not Found' do
            it {
              original_chunks = subject.chunks.all
              subject.chunks.each do |chunk|
                resp = HTTParty.head(
                  "#{subject.storage_provider.storage_url}/#{chunk.sub_path}",
                  headers: subject.storage_provider.auth_header
                )
                expect(resp.response.code.to_i).to eq(200)
              end

              expect {
                subject.storage_provider.delete_object_manifest(subject.storage_container, subject.id)
              }.not_to raise_error

              resp = HTTParty.head(
                "#{subject.storage_provider.storage_url}/#{subject.sub_path}",
                headers: subject.storage_provider.auth_header
              )
              expect(resp.response.code.to_i).to eq(404)

              purge_time = DateTime.now
              expect {
                expect {
                  subject.purge_storage
                }.to change{Chunk.count}.by(-original_chunks.length)
              }.not_to raise_error

              subject.reload
              expect(subject.purged_on).not_to be_nil
              expect(subject.purged_on).to be >= purge_time
              expect(subject.chunks.count).to eq(0)
              original_chunks.each do |chunk|
                resp = HTTParty.head(
                  "#{subject.storage_provider.storage_url}/#{chunk.sub_path}",
                  headers: subject.storage_provider.auth_header
                )
                expect(resp.response.code.to_i).to eq(404)
              end
            }
          end

          context 'Other Exception' do
            let(:fake_storage_provider) { FactoryBot.create(:storage_provider) }
            it {
              #create authentication failure
              original_auth_header = subject.storage_provider.auth_header
              original_storage_url = subject.storage_provider.storage_url
              expect(
                subject.storage_provider.update(
                  service_user: fake_storage_provider.service_user
                )
              ).to be_truthy

              resp = HTTParty.head(
                "#{original_storage_url}/#{subject.sub_path}",
                headers: original_auth_header
              )
              expect(resp.response.code.to_i).to eq(200)

              original_chunks = subject.chunks.all

              subject.chunks.each do |chunk|
                resp = HTTParty.head(
                  "#{original_storage_url}/#{chunk.sub_path}",
                  headers: original_auth_header
                )
                expect(resp.response.code.to_i).to eq(200)
              end

              subject.storage_provider.remove_instance_variable(:'@auth_uri_resp')
              purge_time = DateTime.now
              expect {
                expect {
                  subject.purge_storage
                }.not_to change{Chunk.count}
              }.to raise_error(StorageProviderException)

              subject.reload
              expect(subject.purged_on).to be_nil

              resp = HTTParty.head(
                "#{original_storage_url}/#{subject.sub_path}",
                headers: original_auth_header
              )
              expect(resp.response.code.to_i).to eq(200)

              original_chunks.each do |chunk|
                resp = HTTParty.head(
                  "#{original_url}/#{chunk.sub_path}",
                  headers: original_auth_header
                )
                expect(resp.response.code.to_i).to eq(200)
              end
            }
          end
        end

        context 'no StorageProviderException' do
          it {
            original_chunks = subject.chunks.all
            resp = HTTParty.head(
              "#{subject.storage_provider.storage_url}/#{subject.sub_path}",
              headers: subject.storage_provider.auth_header
            )
            expect(resp.response.code.to_i).to eq(200)
            subject.chunks.each do |chunk|
              resp = HTTParty.head(
                "#{subject.storage_provider.storage_url}/#{chunk.sub_path}",
                headers: subject.storage_provider.auth_header
              )
              expect(resp.response.code.to_i).to eq(200)
            end
            purge_time = DateTime.now
            expect {
              subject.purge_storage
            }.to change{Chunk.count}.by(-original_chunks.length)
            subject.reload
            expect(subject.purged_on).not_to be_nil
            expect(subject.purged_on).to be >= purge_time
            expect(subject.chunks.count).to eq(0)

            resp = HTTParty.head(
              "#{subject.storage_provider.storage_url}/#{subject.sub_path}",
              headers: subject.storage_provider.auth_header
            )
            expect(resp.response.code.to_i).to eq(404)
            original_chunks.each do |chunk|
              resp = HTTParty.head(
                "#{subject.storage_provider.storage_url}/#{chunk.sub_path}",
                headers: subject.storage_provider.auth_header
              )
              expect(resp.response.code.to_i).to eq(404)
            end
          }
        end
      end #calls
    end #purge_storage
  end #swift methods
end
