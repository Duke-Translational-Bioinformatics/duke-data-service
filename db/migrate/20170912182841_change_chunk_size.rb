class ChangeChunkSize < ActiveRecord::Migration[5.0]
  def change
    change_column :chunks, :size, :integer, limit: 8
  end
end
