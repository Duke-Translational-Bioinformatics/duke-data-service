class AddDefaultToActivitiesIsDeleted < ActiveRecord::Migration
  def change
    change_column_default :activities, :is_deleted, false
  end
end
