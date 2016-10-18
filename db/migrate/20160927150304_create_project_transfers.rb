class CreateProjectTransfers < ActiveRecord::Migration
  def change
    create_table :project_transfers, id: :uuid do |t|
      t.string :status
      t.text :status_comment
      t.uuid :project_id
      t.uuid :from_user_id

      t.timestamps null: false
    end
  end
end
