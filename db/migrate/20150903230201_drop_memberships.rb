class DropMemberships < ActiveRecord::Migration
  def up
    drop_table :memberships
  end
  def down
    create_table :memberships, id: :uuid  do |t|
      t.uuid :user_id
      t.uuid :project_id

      t.timestamps null: false
    end
  end
end
