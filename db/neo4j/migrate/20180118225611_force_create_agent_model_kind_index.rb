class ForceCreateAgentModelKindIndex < Neo4j::Migrations::Base
  def up
    add_index :Agent, :model_kind, force: true
  end

  def down
    drop_index :Agent, :model_kind
  end
end
