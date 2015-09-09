class ChangeProjectRoleIsDepricatedToIsDeprecated < ActiveRecord::Migration
  def change
    rename_column :project_roles, :is_depricated, :is_deprecated
  end
end
