class ForceCreateFileVersionModelKindIndex < Neo4j::Migrations::Base
  def up
    add_index :FileVersion, :model_kind, force: true
  end

  def down
    drop_index :FileVersion, :model_kind
  end
end
