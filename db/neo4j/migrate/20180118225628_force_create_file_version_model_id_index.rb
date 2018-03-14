class ForceCreateFileVersionModelIdIndex < Neo4j::Migrations::Base
  def up
    add_index :FileVersion, :model_id, force: true
  end

  def down
    drop_index :FileVersion, :model_id
  end
end
