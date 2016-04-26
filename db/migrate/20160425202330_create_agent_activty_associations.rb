class CreateAgentActivtyAssociations < ActiveRecord::Migration
  def change
    create_table :agent_activity_associations do |t|
      t.references :agent, polymorphic: true, index: true
      t.uuid :activity_id

      t.timestamps null: false
    end
  end
end
