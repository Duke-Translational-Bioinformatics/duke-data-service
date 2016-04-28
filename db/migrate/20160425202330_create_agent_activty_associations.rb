class CreateAgentActivtyAssociations < ActiveRecord::Migration
  def change
    create_table :agent_activity_associations, id: :uuid do |t|
      t.uuid :agent_id
      t.string :agent_type
      t.uuid :activity_id

      t.timestamps null: false
    end
    add_index :agent_activity_associations, :agent_id
  end
end
