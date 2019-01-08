require 'rails_helper'

describe "storage_provider" do
  describe "storage_provider:create" do
    include_context "rake"
    let(:task_name) { "storage_provider:create" }
    let(:expected_supported_storage_provider_types) { ['swift', 's3'] }

    context 'missing ENV[STORAGE_PROVIDER_TYPE]' do
      it {
        invoke_task(expected_stderr: /YOU MUST SET ENV\[STORAGE_PROVIDER_TYPE\] with one of #{expected_supported_storage_provider_types.join(' ')}/)
      }
    end

    context 'unsupported STORAGE_PROVIDER_TYPE' do
      let(:unsupported_type) { 'unsupported' }
      include_context 'with env_override'
      let(:env_override) { {
        'STORAGE_PROVIDER_TYPE' => unsupported_type
      } }
      it {
        invoke_task(expected_stderr: /STORAGE_PROVIDER_TYPE must be one of #{expected_supported_storage_provider_types.join(' ')}/)
      }
    end

    context 'STORAGE_PROVIDER_TYPE swift' do
      context 'missing required Swift ENV' do
        include_context 'with env_override'
        let(:env_override) { {
          'STORAGE_PROVIDER_TYPE' => 'swift'
        } }
        it {
          invoke_task(expected_stderr: /YOU DO NOT HAVE YOUR SWIFT ENVIRONMENT VARIABLES SET/)
        }
      end

      context 'with required Swift ENV' do
        let(:storage_provider_attributes) {
          FactoryBot.attributes_for(:swift_storage_provider)
        }
        include_context 'with env_override'

        context 'invalid SwiftStorageProvider' do
          let(:env_override) {
            {
              'STORAGE_PROVIDER_TYPE' => 'swift',
              'SWIFT_DISPLAY_NAME' => storage_provider_attributes[:display_name],
              'SWIFT_DESCRIPTION' => storage_provider_attributes[:description],
              'SWIFT_ACCT' => storage_provider_attributes[:name],
              'SWIFT_VERSION' => storage_provider_attributes[:provider_version],
              'SWIFT_AUTH_URI' => storage_provider_attributes[:auth_uri],
              'SWIFT_USER' => storage_provider_attributes[:service_user],
              'SWIFT_PASS' => storage_provider_attributes[:service_pass],
              'SWIFT_PRIMARY_KEY' => storage_provider_attributes[:primary_key],
              'SWIFT_SECONDARY_KEY' => storage_provider_attributes[:secondary_key],
              'SWIFT_CHUNK_HASH_ALGORITHM' => storage_provider_attributes[:chunk_hash_algorithm],
              'SWIFT_CHUNK_MAX_NUMBER' => storage_provider_attributes[:chunk_max_number],
              'SWIFT_CHUNK_MAX_SIZE_BYTES' => storage_provider_attributes[:chunk_max_size_bytes]
            }
          }
          it {
            invoke_task(expected_stderr: /Validation Error.*/)
          }
        end

        context 'valid SwiftStorageProvider' do
          let(:env_override) {
            {
              'STORAGE_PROVIDER_TYPE' => 'swift',
              'SWIFT_DISPLAY_NAME' => storage_provider_attributes[:display_name],
              'SWIFT_DESCRIPTION' => storage_provider_attributes[:description],
              'SWIFT_ACCT' => storage_provider_attributes[:name],
              'SWIFT_URL_ROOT' => storage_provider_attributes[:url_root],
              'SWIFT_VERSION' => storage_provider_attributes[:provider_version],
              'SWIFT_AUTH_URI' => storage_provider_attributes[:auth_uri],
              'SWIFT_USER' => storage_provider_attributes[:service_user],
              'SWIFT_PASS' => storage_provider_attributes[:service_pass],
              'SWIFT_PRIMARY_KEY' => storage_provider_attributes[:primary_key],
              'SWIFT_SECONDARY_KEY' => storage_provider_attributes[:secondary_key],
              'SWIFT_CHUNK_HASH_ALGORITHM' => storage_provider_attributes[:chunk_hash_algorithm],
              'SWIFT_CHUNK_MAX_NUMBER' => storage_provider_attributes[:chunk_max_number],
              'SWIFT_CHUNK_MAX_SIZE_BYTES' => storage_provider_attributes[:chunk_max_size_bytes]
            }
          }
          it {
            expect {
              invoke_task
            }.to change{SwiftStorageProvider.count}.by(1)
            expect(SwiftStorageProvider.where(
              name: storage_provider_attributes[:name]
            )).to exist
          }
        end
      end
    end

    context 'STORAGE_PROVIDER_TYPE s3' do
      context 'missing required S3 ENV' do
        include_context 'with env_override'
        let(:env_override) { {
          'STORAGE_PROVIDER_TYPE' => 's3'
        } }
        it {
          invoke_task(expected_stderr: /YOU DO NOT HAVE YOUR S3 ENVIRONMENT VARIABLES SET/)
        }
      end

      context 'with required S3 ENV' do
        let(:storage_provider_attributes) {
          FactoryBot.attributes_for(:s3_storage_provider)
        }
        include_context 'with env_override'

        context 'invalid S3StorageProvider' do
          let(:env_override) {
            {
              'STORAGE_PROVIDER_TYPE' => 's3',
              'S3_DISPLAY_NAME' => storage_provider_attributes[:display_name],
              'S3_DESCRIPTION' => storage_provider_attributes[:description],
              'S3_ACCT' => storage_provider_attributes[:name],
              'S3_VERSION' => storage_provider_attributes[:provider_version],
              'S3_AUTH_URI' => storage_provider_attributes[:auth_uri],
              'S3_USER' => storage_provider_attributes[:service_user],
              'S3_PASS' => storage_provider_attributes[:service_pass],
              'S3_PRIMARY_KEY' => storage_provider_attributes[:primary_key],
              'S3_SECONDARY_KEY' => storage_provider_attributes[:secondary_key],
              'S3_CHUNK_HASH_ALGORITHM' => storage_provider_attributes[:chunk_hash_algorithm],
              'S3_CHUNK_MAX_NUMBER' => storage_provider_attributes[:chunk_max_number],
              'S3_CHUNK_MAX_SIZE_BYTES' => storage_provider_attributes[:chunk_max_size_bytes]
            }
          }
          it {
            invoke_task(expected_stderr: /Validation Error.*/)
          }
        end

        context 'valid S3StorageProvider' do
          let(:env_override) {
            {
              'STORAGE_PROVIDER_TYPE' => 's3',
              'S3_DISPLAY_NAME' => storage_provider_attributes[:display_name],
              'S3_DESCRIPTION' => storage_provider_attributes[:description],
              'S3_ACCT' => storage_provider_attributes[:name],
              'S3_URL_ROOT' => storage_provider_attributes[:url_root],
              'S3_VERSION' => storage_provider_attributes[:provider_version],
              'S3_AUTH_URI' => storage_provider_attributes[:auth_uri],
              'S3_USER' => storage_provider_attributes[:service_user],
              'S3_PASS' => storage_provider_attributes[:service_pass],
              'S3_PRIMARY_KEY' => storage_provider_attributes[:primary_key],
              'S3_SECONDARY_KEY' => storage_provider_attributes[:secondary_key],
              'S3_CHUNK_HASH_ALGORITHM' => storage_provider_attributes[:chunk_hash_algorithm],
              'S3_CHUNK_MAX_NUMBER' => storage_provider_attributes[:chunk_max_number],
              'S3_CHUNK_MAX_SIZE_BYTES' => storage_provider_attributes[:chunk_max_size_bytes]
            }
          }
          it {
            expect {
              invoke_task
            }.to change{S3StorageProvider.count}.by(1)
            expect(S3StorageProvider.where(
              name: storage_provider_attributes[:name]
            )).to exist
          }
        end
      end
    end
  end
end
