class ForceCreateFileVersionUuidConstraint < Neo4j::Migrations::Base
  def up
    add_constraint :FileVersion, :uuid, force: true
  end

  def down
    drop_constraint :FileVersion, :uuid
  end
end
