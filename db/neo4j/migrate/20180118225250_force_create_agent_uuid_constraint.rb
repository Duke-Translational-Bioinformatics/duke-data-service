class ForceCreateAgentUuidConstraint < Neo4j::Migrations::Base
  def up
    add_constraint :Agent, :uuid, force: true
  end

  def down
    drop_constraint :Agent, :uuid
  end
end
