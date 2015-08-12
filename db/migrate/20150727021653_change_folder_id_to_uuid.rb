class ChangeFolderIdToUuid < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'
    create_table :folders, id: :uuid  do |t|
      t.string :name
      t.uuid :parent_id

      t.timestamps null: false
    end
  end
end
