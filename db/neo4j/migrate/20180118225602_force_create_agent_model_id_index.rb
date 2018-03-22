class ForceCreateAgentModelIdIndex < Neo4j::Migrations::Base
  def up
    add_index :Agent, :model_id, force: true
  end

  def down
    drop_index :Agent, :model_id
  end
end
