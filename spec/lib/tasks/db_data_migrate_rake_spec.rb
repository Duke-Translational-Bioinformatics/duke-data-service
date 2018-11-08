require 'rails_helper'

describe "db:data:migrate" do
  include_context "rake"
  include_context 'mock all Uploads StorageProvider'

  let(:task_path) { "lib/tasks/db_data_migrate" }
  let(:current_user) { FactoryBot.create(:user) }
  let(:file_version_audits) { Audited.audit_class.where(auditable: FileVersion.all) }
  let(:data_file_audits) { Audited.audit_class.where(auditable: DataFile.all) }

  it { expect(subject.prerequisites).to  include("environment") }

  describe "#invoke" do
    context 'when creating fingerprints' do
      let(:fingerprint_upload) { FactoryBot.create(:fingerprint).upload }
      let(:incomplete_upload_with_fingerprint_value) { FactoryBot.create(:upload, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5') }
      let(:upload_with_fingerprint_value) { FactoryBot.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5', storage_provider: mocked_storage_provider) }
      let(:upload_with_capitalized_algorithm) { FactoryBot.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'MD5', storage_provider: mocked_storage_provider) }
      let(:upload_with_invalid_fingerprint_algorithm) { FactoryBot.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5000', storage_provider: mocked_storage_provider) }
      context 'for upload without fingerprint_value' do
        before { FactoryBot.create(:upload, storage_provider: mocked_storage_provider) }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for incomplete upload with fingerprint_value' do
        before { expect(incomplete_upload_with_fingerprint_value).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(0) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(0) }
      end
      context 'for upload with fingerprint_value' do
        before { expect(upload_with_fingerprint_value).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(1) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }
      end
      context 'for upload with capitalized algorithm' do
        before { expect(upload_with_capitalized_algorithm).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(1) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }
      end
      context 'for upload with invalid fingerprint_algorithm' do
        before { expect(upload_with_invalid_fingerprint_algorithm).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(0) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(0) }
      end
      context 'for upload with associated fingerprint' do
        before { expect(fingerprint_upload).to be_persisted }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for upload with associated fingerprint and fingerprint_value' do
        let(:fingerprint) { FactoryBot.create(:fingerprint, upload: upload_with_fingerprint_value) }
        before { expect(fingerprint).to be_persisted }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
    end

    context 'without any untyped authentication services' do
      let(:duke_authentication_service) { FactoryBot.create(:duke_authentication_service) }
      let(:openid_authentication_service) { FactoryBot.create(:openid_authentication_service) }

      it {
        expect(duke_authentication_service).to be_persisted
        expect(openid_authentication_service).to be_persisted
        expect {
          invoke_task expected_stderr: /0 untyped authentication_services changed/
        }.not_to change{
          AuthenticationService.where(type: nil).count
        }
      }
    end

    context 'with untyped authentication services' do
      let(:default_type) { DukeAuthenticationService }
      let(:untyped_authentication_service) {
        AuthenticationService.create(FactoryBot.attributes_for(:duke_authentication_service))
      }
      let(:openid_authentication_service) { FactoryBot.create(:openid_authentication_service) }

      it {
        expect(untyped_authentication_service).not_to be_a default_type
        expect(openid_authentication_service).to be_persisted
        expect {
          invoke_task expected_stderr: Regexp.new("1 untyped authentication_services changed to #{default_type}")
        }.to change{
          AuthenticationService.where(type: nil).count
        }.by(-1)
        expected_to_be_typed_auth_service = AuthenticationService.find(untyped_authentication_service.id)
        expect(expected_to_be_typed_auth_service).to be_a default_type
        openid_authentication_service.reload
        expect(openid_authentication_service).to be_a OpenidAuthenticationService
      }
    end

    context 'without untyped storage providers' do
      let(:storage_provider) { FactoryBot.create(:swift_storage_provider) }
      it {
        expect(storage_provider).to be_persisted
        expect {
          invoke_task expected_stderr: /0 untyped storage_providers changed/
        }.not_to change{
          StorageProvider.where(type: nil).count
        }
      }
    end

    context 'with untyped storage providers' do
      let(:default_type) { SwiftStorageProvider }
      let(:untyped_storage_provider) {
        StorageProvider.create(FactoryBot.attributes_for(:swift_storage_provider))
      }
      let(:typed_storage_provider) { FactoryBot.create(:swift_storage_provider) }

      it {
        expect(untyped_storage_provider).not_to be_a default_type
        expect(typed_storage_provider).to be_persisted
        expect {
          invoke_task expected_stderr: Regexp.new("1 untyped storage_providers changed to #{default_type}")
        }.to change{
          StorageProvider.where(type: nil).count
        }.by(-1)
        expected_to_be_typed_storage_provider = StorageProvider.find(untyped_storage_provider.id)
        expect(expected_to_be_typed_storage_provider).to be_a default_type
        typed_storage_provider.reload
        expect(typed_storage_provider).to be_a SwiftStorageProvider
      }
    end

    context 'without any storage providers' do
      it {
        expect(StorageProvider.any?).to be_falsey
        expect {
          invoke_task expected_stdout: /no storage_providers found/
        }.not_to change{
          StorageProvider.where(is_default: true).count
        }
      }
    end

    context 'with a default storage provider' do
      let(:storage_provider) { FactoryBot.create(:swift_storage_provider) }
      it {
        expect(storage_provider).to be_persisted
        expect(StorageProvider.where(is_default: true).any?).to be_truthy
        expect {
          invoke_task expected_stdout: /0 storage_provider default statuses changed/
        }.not_to change{
          StorageProvider.where(is_default: true).count
        }
      }
    end

    context 'without any default storage providers' do
      let(:not_default_storage_provider) {
        FactoryBot.create(:swift_storage_provider, is_default: false)
      }

      it {
        expect(StorageProvider.where(is_deprecated: true).any?).to be_falsey
        expect(not_default_storage_provider.is_default?).to be_falsey
        expect {
          invoke_task expected_stdout: Regexp.new(/first storage_provider changed to default storage_provider/)
        }.to change{
          StorageProvider.where(is_default: true).count
        }.by(1)
        not_default_storage_provider.reload
        expect(not_default_storage_provider.is_default?).to be_truthy
      }
    end

    shared_examples 'a consistency migration' do |prep_method_sym|
      let(:record_class) { record.class }
      before do
        expect(record).to be_persisted
      end
      context 'record is consistent' do
        let(:prep_method) { send(prep_method_sym) }
        before do
          expect { prep_method }.not_to raise_error
        end
        it 'should update is_consistent to true' do
          expect(record_class.where(is_consistent: nil)).to exist
          invoke_task
          expect(record_class.where(is_consistent: nil)).not_to exist
          record.reload
          expect(record.is_consistent).to eq true
        end
      end

      context 'record is not consistent' do
        it 'should update is_consistent to false' do
          expect(record_class.where(is_consistent: nil)).to exist
          invoke_task
          expect(record_class.where(is_consistent: nil)).not_to exist
          record.reload
          expect(record.is_consistent).to eq false
        end
      end
    end

    describe 'consistency migration' do
      before do
        allow(StorageProvider).to receive(:default)
          .and_return(mocked_storage_provider)
      end

      context 'for project' do
        let(:record) { FactoryBot.create(:project, is_consistent: nil) }
        let(:init_project_storage) {
          expect(mocked_storage_provider).to receive(:is_initialized?)
            .with(record)
            .and_return(true)
        }

        before do
          # this should be overridden by init_project_storage when
          # it is called
          allow(mocked_storage_provider).to receive(:is_initialized?)
            .with(record)
            .and_return(false)
        end

        it_behaves_like 'a consistency migration', :init_project_storage

        context 'with deleted project' do
          before do
            Project.delete_all
            FactoryBot.create(:project, :deleted, is_consistent: nil)
          end
          it 'should not update the consistency status' do
            expect(Project.where(is_consistent: nil)).to exist
            expect {invoke_task}.not_to change{Project.where(is_consistent: nil).count}
          end
        end
      end

      context 'for upload' do
        let(:record) { FactoryBot.create(:upload, is_consistent: nil) }
        let(:init_upload) {
          expect(mocked_storage_provider).to receive(:is_complete_chunked_upload?)
            .with(record)
            .and_return(true)
        }

        before do
          # this should be overridden by init_upload when
          # it is called
          allow(mocked_storage_provider).to receive(:is_complete_chunked_upload?)
            .with(record)
            .and_return(false)
        end
        it_behaves_like 'a consistency migration', :init_upload
      end
    end

    describe 'upload storage_container migration' do
      context 'when there are uploads with nil storage_provider' do
        let(:expected_uploads_without_storage_container) { 3 }
        before do
          Upload.skip_callback(:create, :before, :set_storage_container)
          expected_uploads_without_storage_container.times do
            u = FactoryBot.create(:upload)
          end
        end

        after do
          Upload.set_callback(:create, :before, :set_storage_container)
        end

        it {
          expect(Upload.where(storage_container: nil).count).to eq(expected_uploads_without_storage_container)
          expect {
            invoke_task expected_stdout: Regexp.new("#{expected_uploads_without_storage_container} uploads updated")
          }.to change{
            Upload.where(storage_container: nil).count
          }.by(-expected_uploads_without_storage_container)
          Upload.all.each do |upload|
            expect(upload.storage_container).to eq(upload.project_id)
          end
        }
      end

      context 'when there are no uploads with nil storage_provider' do
        it {
          expect {
            invoke_task expected_stdout: Regexp.new("0 uploads updated")
          }.not_to change{
            Upload.where(storage_container: nil).count
          }
        }
      end
    end

    describe 'migrate_storage_provider_chunk_environment' do
      let(:bad_storage_providers) {
        StorageProvider.where(
          chunk_max_size_bytes: nil,
          chunk_max_number: nil
        ).count
      }

      context 'a storage_provider has nil chunk_max_size_bytes, chunk_max_number' do
        let(:storage_provider) {
          FactoryBot.create(:storage_provider, :skip_validation,
            chunk_max_size_bytes: nil,
            chunk_max_number: nil
          )
        }

        context 'ENV includes SWIFT_CHUNK_MAX_NUMBER and SWIFT_CHUNK_MAX_SIZE_BYTES' do
          include_context 'with env_override'
          let(:env_override) { {
            'SWIFT_CHUNK_MAX_NUMBER' => 1,
            'SWIFT_CHUNK_MAX_SIZE_BYTES' => 5
          } }

          it {
            expect(storage_provider).to be_persisted
            expect(bad_storage_providers).to be > 0
            expect{invoke_task}.to change{
              StorageProvider.where(
                chunk_max_size_bytes: nil,
                chunk_max_number: nil
              ).count
            }.by(-bad_storage_providers)
          }
        end

        context 'ENV does not include SWIFT_CHUNK_MAX_NUMBER and SWIFT_CHUNK_MAX_SIZE_BYTES' do
          before do
            expect(ENV['SWIFT_CHUNK_MAX_NUMBER']).to be_nil
            expect(ENV['SWIFT_CHUNK_MAX_SIZE_BYTES']).to be_nil
          end

          it {
            expect(storage_provider).to be_persisted
            expect(bad_storage_providers).to be > 0
            invoke_task expected_stderr: /please set ENV\[SWIFT_CHUNK_MAX_NUMBER\] AND ENV\[SWIFT_CHUNK_MAX_SIZE_BYTES\]/
          }
        end
      end

      context 'no storage_providers have nil chunk_max_size_bytes, chunk_max_number' do
        let(:storage_provider) { FactoryBot.create(:storage_provider) }

        context 'ENV includes SWIFT_CHUNK_MAX_NUMBER and SWIFT_CHUNK_MAX_SIZE_BYTES' do
          include_context 'with env_override'
          let(:env_override) { {
            'SWIFT_CHUNK_MAX_NUMBER' => 1,
            'SWIFT_CHUNK_MAX_SIZE_BYTES' => 5
          } }

          it {
            expect(storage_provider).to be_persisted
            expect(bad_storage_providers).to eq 0
            expect {invoke_task}.not_to change{ StorageProvider.where(
              chunk_max_size_bytes: nil,
              chunk_max_number: nil
            ).count }
          }
        end

        context 'ENV does not include SWIFT_CHUNK_MAX_NUMBER and SWIFT_CHUNK_MAX_SIZE_BYTES' do
          before do
            expect(ENV['SWIFT_CHUNK_MAX_NUMBER']).to be_nil
            expect(ENV['SWIFT_CHUNK_MAX_SIZE_BYTES']).to be_nil
          end

          it {
            expect(storage_provider).to be_persisted
            expect(bad_storage_providers).to eq 0
            expect {invoke_task}.not_to change{ StorageProvider.where(
              chunk_max_size_bytes: nil,
              chunk_max_number: nil
            ).count }
          }
        end
      end
    end

    describe 'purge_deleted_objects' do
      let(:deleted_project) { FactoryBot.create(:project, is_deleted: true) }

      let(:deleted_folder) { FactoryBot.create(:folder, is_deleted: true) }
      let(:deleted_folder_in_deleted_project) { FactoryBot.create(:folder, :root, project: deleted_project, is_deleted: true) }
      let(:deleted_folder_in_deleted_parent) { FactoryBot.create(:folder, parent: deleted_folder, is_deleted: true) }

      let(:deleted_file) { FactoryBot.create(:data_file, is_deleted: true) }
      let(:deleted_file_in_deleted_project) { FactoryBot.create(:data_file, :root, project: deleted_project, is_deleted: true) }
      let(:deleted_file_in_deleted_parent) { FactoryBot.create(:data_file, parent: deleted_folder, is_deleted: true) }

      let(:deleted_file_version) { FactoryBot.create(:file_version, is_deleted: true) }
      let(:deleted_file_version_in_deleted_file) { FactoryBot.create(:file_version, data_file: deleted_file) }
      let(:expected_transaction_state) { 'trashbin_migration' }

      before(:each) do
        purgables = [
          deleted_folder, deleted_folder_in_deleted_project, deleted_folder_in_deleted_parent,
          deleted_file, deleted_file_in_deleted_project, deleted_file_in_deleted_parent,
          deleted_file_version, deleted_file_version_in_deleted_file
        ]
        expect(deleted_project).to be_persisted
        expect(purgables).to all( be_persisted )
        expect(purgables).to all( have_attributes(is_purged: false) )
      end

      context 'ENV[\"PURGE_OBJECTS\"] not set' do
        it 'does not create job transactions or purge containers' do
          expect(ENV["PURGE_OBJECTS"]).to be_nil
          expect {
            expect {
              invoke_task
            }.not_to change{
              JobTransaction.where(key: 'test.child_purgation', state: 'initialized').count
            }
          }.not_to change{
            Container.where(is_purged: true).count
          }
        end
      end

      context 'ENV[\"PURGE_OBJECTS\"] set' do
        include_context 'with env_override'
        let(:env_override) { {
          'PURGE_OBJECTS' => "1"
        } }

        it 'creates job transactions and purges containers' do
          expect(ENV["PURGE_OBJECTS"]).to eq '1'
          expect {
            expect {
              invoke_task
            }.to change{
              JobTransaction.where(key: 'test.child_purgation', state: 'initialized').count
            }.by(3)
          }.to change{
            Container.where(is_purged: true).count
          }.by(2)
        end
      end
    end

    describe 'populate_nil_project_slugs' do
      let(:projects) { FactoryBot.build_list(:project, 4, name: 'foo') }
      let(:slugged_project) { FactoryBot.create(:project, :with_slug) }
      let(:original_slug) { slugged_project.slug }
      before do
        expect(projects).not_to be_empty
        projects.each_with_index do |p, i|
          p.is_deleted = (i%2 == 0)
          p.save(validate: false)
        end
        expect(projects[0]).to be_is_deleted
        expect(projects[1]).not_to be_is_deleted
        expect(projects[2]).to be_is_deleted
        expect(projects[3]).not_to be_is_deleted
        expect(projects).to all( have_attributes(name: 'foo').and be_slug_is_blank )
        expect(original_slug).not_to be_blank
        expect {
          invoke_task expected_stdout: Regexp.new("Populate Project slugs:\n.... 4 Project slugs populated.")
        }.to change{
          Project.where(slug: nil).count
        }.by(-4)
      end
      it 'populates nil project slugs ordered by !is_deleted, oldest first' do
        expect(projects.map(&:reload)).to all( be_truthy )
        expect(projects[1].slug).to eq('foo')
        expect(projects[3].slug).to eq('foo_1')
        expect(projects[0].slug).to eq('foo_2')
        expect(projects[2].slug).to eq('foo_3')
      end
      it 'leaves existing slugs alone' do
        expect(slugged_project.reload).to be_truthy
        expect(slugged_project.slug).to eq original_slug
      end
    end
  end
end
