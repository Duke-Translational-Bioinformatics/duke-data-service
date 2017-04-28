class AddDefaultToActivitiesIsDeleted < ActiveRecord::Migration[4.2]
  def change
    change_column_default :activities, :is_deleted, false
  end
end
