class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :software_agent_id
      t.string :key

      t.timestamps null: false
    end
  end
end
