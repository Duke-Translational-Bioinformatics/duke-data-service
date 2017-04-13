class AddChunkHashAlgorithmToStorageProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :storage_providers, :chunk_hash_algorithm, :string, default: 'md5'
  end
end
