class ForceCreateFileVersionIsDeletedIndex < Neo4j::Migrations::Base
  def up
    add_index :FileVersion, :is_deleted, force: true
  end

  def down
    drop_index :FileVersion, :is_deleted
  end
end
