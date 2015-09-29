class ChangeUserIdOnAudits < ActiveRecord::Migration
  def change
    change_column :audits, :user_id, :string
  end
end
