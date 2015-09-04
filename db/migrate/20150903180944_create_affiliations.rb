class CreateAffiliations < ActiveRecord::Migration
  def change
    create_table :affiliations do |t|
      t.uuid :project_id
      t.uuid :user_id
      t.string :project_role_id

      t.timestamps null: false
    end
  end
end
