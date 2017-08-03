class ChangeProjectTransferStatusToInteger < ActiveRecord::Migration[4.2]
  def change
    drop_table :project_transfers
    create_table :project_transfers, id: :uuid do |t|
      t.integer :status
      t.text :status_comment
      t.uuid :project_id
      t.uuid :from_user_id

      t.timestamps null: false
    end
  end
end
