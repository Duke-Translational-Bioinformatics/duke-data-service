class AddChunkMaxNumberChunkMaxSizeBytesToStorageProviders < ActiveRecord::Migration[5.0]
  def change
    add_column :storage_providers, :chunk_max_number, :integer
    add_column :storage_providers, :chunk_max_size_bytes, :integer, limit: 8
  end
end
