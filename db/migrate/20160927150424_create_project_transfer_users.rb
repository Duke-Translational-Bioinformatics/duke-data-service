class CreateProjectTransferUsers < ActiveRecord::Migration
  def change
    create_table :project_transfer_users, id: :uuid do |t|
      t.uuid :project_transfer_id
      t.uuid :to_user_id

      t.timestamps null: false
    end
  end
end
