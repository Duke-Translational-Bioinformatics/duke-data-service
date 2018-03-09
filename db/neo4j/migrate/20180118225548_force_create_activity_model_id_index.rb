class ForceCreateActivityModelIdIndex < Neo4j::Migrations::Base
  def up
    add_index :Activity, :model_id, force: true
  end

  def down
    drop_index :Activity, :model_id
  end
end
