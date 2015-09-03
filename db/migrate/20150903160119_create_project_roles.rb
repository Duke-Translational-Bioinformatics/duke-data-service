class CreateProjectRoles < ActiveRecord::Migration
  def change
    create_table :project_roles, id: false do |t|
      t.string :id, null: false
      t.string :name
      t.string :description
      t.boolean :is_depricated

      t.timestamps null: false
    end
  end
end
