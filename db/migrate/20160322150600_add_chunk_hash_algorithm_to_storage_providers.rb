class AddChunkHashAlgorithmToStorageProviders < ActiveRecord::Migration
  def change
    add_column :storage_providers, :chunk_hash_algorithm, :string, default: 'md5'
  end
end
