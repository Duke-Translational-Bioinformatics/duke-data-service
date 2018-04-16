require 'rails_helper'

describe "db:data:migrate" do
  include_context "rake"
  let(:task_path) { "lib/tasks/db_data_migrate" }
  let(:current_user) { FactoryBot.create(:user) }
  let(:file_version_audits) { Audited.audit_class.where(auditable: FileVersion.all) }
  let(:data_file_audits) { Audited.audit_class.where(auditable: DataFile.all) }

  it { expect(subject.prerequisites).to  include("environment") }

  describe "#invoke" do
    context 'when creating fingerprints' do
      let(:fingerprint_upload) { FactoryBot.create(:fingerprint).upload }
      let(:incomplete_upload_with_fingerprint_value) { FactoryBot.create(:upload, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5') }
      let(:upload_with_fingerprint_value) { FactoryBot.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5') }
      let(:upload_with_capitalized_algorithm) { FactoryBot.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'MD5') }
      let(:upload_with_invalid_fingerprint_algorithm) { FactoryBot.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5000') }
      context 'for upload without fingerprint_value' do
        before { FactoryBot.create(:upload) }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for incomplete upload with fingerprint_value' do
        before { expect(incomplete_upload_with_fingerprint_value).to be_persisted }
        it { invoke_task(expected_stdout: /Creating fingerprints for 0 uploads/) }
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

    describe 'consistency migration', :vcr do
      let(:storage_provider) { FactoryBot.create(:storage_provider, :swift) }

      before do
        expect(storage_provider).to be_persisted
      end

      context 'for project' do
        let(:record) { FactoryBot.create(:project, is_consistent: nil) }
        let(:init_project_storage) {
          storage_provider.put_container(record.id)
          expect(storage_provider.get_container_meta(record.id)).not_to be_nil
        }
        it_behaves_like 'a consistency migration', :init_project_storage

        context 'with deleted project' do
          before(:each) { FactoryBot.create(:project, :deleted, is_consistent: nil) }
          it { expect {invoke_task}.not_to change{Project.where(is_consistent: nil).count} }
        end
      end

      context 'for upload' do
        let(:record) { FactoryBot.create(:upload, is_consistent: nil, storage_provider: storage_provider) }
        let(:init_upload) {
          storage_provider.put_container(record.project.id)
          expect(storage_provider.get_container_meta(record.project.id)).not_to be_nil
          record.create_and_validate_storage_manifest
          record.update_columns(is_consistent: nil)
          expect(storage_provider.get_object_metadata(record.project.id, record.id)).not_to be_nil
        }
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
      context 'ENV[\"PURGE_OBJECTS\"] not set' do
        it {
          expect(Project).to receive(:where).with(hash_excluding(:is_deleted => true)).and_call_original
          expect(Project).not_to receive(:where).with(is_deleted: true)
          expect(Folder).not_to receive(:where).with(is_deleted: true)
          expect(DataFile).not_to receive(:where).with(is_deleted: true)
          expect(FileVersion).not_to receive(:where).with(is_deleted: true)
          invoke_task
        }
      end

      context 'ENV[\"PURGE_OBJECTS\"] set' do
        include_context 'with env_override'
        let(:env_override) { {
          'PURGE_OBJECTS' => "1"
        } }
        let(:project_relation) { Project.where(is_deleted: true) }
        let(:deleted_project) { FactoryBot.create(:project, is_deleted: true) }

        let(:folder_relation) { Folder.where(is_deleted: true, is_purged: false) }
        let(:deleted_folder) { FactoryBot.create(:folder, is_deleted: true) }
        let(:deleted_folder_in_deleted_project) { FactoryBot.create(:folder, :root, project: deleted_project, is_deleted: true) }
        let(:deleted_folder_in_deleted_parent) { FactoryBot.create(:folder, parent: deleted_folder, is_deleted: true) }

        let(:file_relation) { DataFile.where(is_deleted: true, is_purged: false) }
        let(:deleted_file) { FactoryBot.create(:data_file, is_deleted: true) }
        let(:deleted_file_in_deleted_project) { FactoryBot.create(:data_file, :root, project: deleted_project, is_deleted: true) }
        let(:deleted_file_in_deleted_parent) { FactoryBot.create(:data_file, parent: deleted_folder, is_deleted: true) }

        let(:file_version_relation) { FileVersion.where(is_deleted: true, is_purged: false) }
        let(:deleted_file_version) { FactoryBot.create(:file_version, is_deleted: true) }
        let(:deleted_file_version_in_deleted_file) { FactoryBot.create(:file_version, data_file: deleted_file) }

        it {
          expect(project_relation).to receive(:all).and_return([ deleted_project ])
          expect(deleted_project).to receive(:force_purgation=).with(true).and_call_original
          expect(deleted_project).to receive(:manage_deletion)
          expect(deleted_project).to receive(:manage_children)
          expect(Project).to receive(:where).with(hash_excluding(:is_deleted => true)).and_call_original
          expect(Project).to receive(:where).with(is_deleted: true).and_return(project_relation)


          expect(folder_relation).to receive(:all).and_return( [ deleted_folder, deleted_folder_in_deleted_project, deleted_folder_in_deleted_parent ] )
          expect(deleted_folder).to receive(:update).with(is_deleted: true, is_purged: true)
          expect(deleted_folder_in_deleted_project).not_to receive(:update)
          expect(deleted_folder_in_deleted_parent).not_to receive(:update)
          expect(Folder).to receive(:where).with(is_deleted: true, is_purged: false).and_return(folder_relation)

          expect(file_relation).to receive(:all).and_return( [ deleted_file, deleted_file_in_deleted_project, deleted_file_in_deleted_parent ] )
          expect(deleted_file).to receive(:update).with(is_deleted: true, is_purged: true)
          expect(deleted_file_in_deleted_project).not_to receive(:update)
          expect(deleted_file_in_deleted_parent).not_to receive(:update)
          expect(DataFile).to receive(:where).with(is_deleted: true, is_purged: false).and_return(file_relation)

          expect(file_version_relation).to receive(:all).and_return( [ deleted_file_version, deleted_file_version_in_deleted_file ] )
          expect(deleted_file_version).to receive(:update).with(is_deleted: true, is_purged: true)
          expect(deleted_file_version_in_deleted_file).not_to receive(:update)
          expect(FileVersion).to receive(:where).with(is_deleted: true, is_purged: false).and_return(file_version_relation)

          invoke_task
        }
      end
    end
  end
end
