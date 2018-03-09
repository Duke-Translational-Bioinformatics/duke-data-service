class ForceCreateActivityModelKindIndex < Neo4j::Migrations::Base
  def up
    add_index :Activity, :model_kind, force: true
  end

  def down
    drop_index :Activity, :model_kind
  end
end
