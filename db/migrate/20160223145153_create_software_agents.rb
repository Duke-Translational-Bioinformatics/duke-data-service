class CreateSoftwareAgents < ActiveRecord::Migration
  def change
    create_table :software_agents, id: :uuid do |t|
      t.string :name
      t.string :description
      t.uuid :creator_id
      t.string :repo_url
      t.boolean :is_deleted, :default => false

      t.timestamps null: false
    end
  end
end
