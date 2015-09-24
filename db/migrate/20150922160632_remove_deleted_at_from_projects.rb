class RemoveDeletedAtFromProjects < ActiveRecord::Migration
  def change
    remove_column :projects, :deleted_at, :datetime
  end
end
