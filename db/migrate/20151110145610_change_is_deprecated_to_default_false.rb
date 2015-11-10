class ChangeIsDeprecatedToDefaultFalse < ActiveRecord::Migration
  def change
    change_column :auth_roles, :is_deprecated, :boolean, null: false, default: false
    change_column :storage_providers, :is_deprecated, :boolean, null: false, default: false
    change_column :project_roles, :is_deprecated, :boolean, null: false, default: false
  end
end

