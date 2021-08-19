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

    context 'STORAGE_PROVIDER_TYPE single_bucket_s3' do
      context 'missing required SINGLE BUCKET S3 ENV' do
        include_context 'with env_override'
        let(:env_override) { {
          'STORAGE_PROVIDER_TYPE' => 'single_bucket_s3'
        } }
        it {
          invoke_task(expected_stderr: /YOU DO NOT HAVE YOUR SINGLE BUCKET S3 ENVIRONMENT VARIABLES SET/)
        }
      end

      context 'with required SINGLE BUCKET S3 ENV' do
        before(:example) do
          allow_any_instance_of(SingleBucketS3StorageProvider).to receive(:client).and_return(Aws::S3::Client.new(stub_responses: true))
        end
        let(:storage_provider_attributes) {
          FactoryBot.attributes_for(:single_bucket_s3_storage_provider)
        }
        include_context 'with env_override'

        context 'invalid SingleBucketS3StorageProvider' do
          let(:env_override) {
            {
              'STORAGE_PROVIDER_TYPE' => 'single_bucket_s3',
              'SINGLE_BUCKET_S3_DISPLAY_NAME' => storage_provider_attributes[:display_name],
              'SINGLE_BUCKET_S3_DESCRIPTION' => storage_provider_attributes[:description],
              'SINGLE_BUCKET_S3_ACCT' => storage_provider_attributes[:name],
              'SINGLE_BUCKET_S3_CHUNK_HASH_ALGORITHM' => storage_provider_attributes[:chunk_hash_algorithm]
            }
          }
          it {
            invoke_task(expected_stderr: /Validation Error.*/)
          }
        end

        context 'valid SingleBucketS3StorageProvider' do
          before(:example) do
            allow_any_instance_of(SingleBucketS3StorageProvider).to receive(:configure) do
              $stderr.puts 'SingleBucketS3StorageProvider#configure called'
            end
          end
          let(:env_override) {
            {
              'STORAGE_PROVIDER_TYPE' => 'single_bucket_s3',
              'SINGLE_BUCKET_S3_DISPLAY_NAME' => storage_provider_attributes[:display_name],
              'SINGLE_BUCKET_S3_DESCRIPTION' => storage_provider_attributes[:description],
              'SINGLE_BUCKET_S3_ACCT' => storage_provider_attributes[:name],
              'SINGLE_BUCKET_S3_USER' => storage_provider_attributes[:service_user],
              'SINGLE_BUCKET_S3_PASS' => storage_provider_attributes[:service_pass],
              'SINGLE_BUCKET_S3_CHUNK_HASH_ALGORITHM' => storage_provider_attributes[:chunk_hash_algorithm],
              'SINGLE_BUCKET_S3_BUCKET_NAME' => storage_provider_attributes[:bucket_name]
            }
          }
          context 'without existing instance' do
            before(:example) do
              expect(SingleBucketS3StorageProvider.where(
                name: storage_provider_attributes[:name]
              )).not_to exist
            end
            it { invoke_task(expected_stderr: /Configuring.*/) }
            it { invoke_task(expected_stderr: /SingleBucketS3StorageProvider#configure called.*/) }
            it {
              expect {
                invoke_task
              }.to change{SingleBucketS3StorageProvider.count}.by(1)
              expect(SingleBucketS3StorageProvider.where(
                name: storage_provider_attributes[:name]
              )).to exist
            }
          end
          context 'with existing instance' do
            before(:example) do
              FactoryBot.create(
                :single_bucket_s3_storage_provider,
                name: storage_provider_attributes[:name]
              )
            end
            it {
              invoke_task(expected_stderr: /Storage provider '#{storage_provider_attributes[:name]}' already exists.*/)
            }
            it {
              expect {
                invoke_task
              }.not_to change{SingleBucketS3StorageProvider.count}
              expect(SingleBucketS3StorageProvider.where(
                name: storage_provider_attributes[:name]
              )).to exist
            }
          end
        end
      end
    end
  end
end
