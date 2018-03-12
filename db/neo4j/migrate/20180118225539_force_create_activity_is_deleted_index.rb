class ForceCreateActivityIsDeletedIndex < Neo4j::Migrations::Base
  def up
    add_index :Activity, :is_deleted, force: true
  end

  def down
    drop_index :Activity, :is_deleted
  end
end
