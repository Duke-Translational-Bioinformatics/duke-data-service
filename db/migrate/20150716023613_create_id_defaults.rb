class CreateIdDefaults < ActiveRecord::Migration
  def up
    change_column_default :users, :id, nil
    change_column_default :projects, :id, nil
    change_column_default :memberships, :id, nil
  end

  def down
    change_column_default :users, :id, nil
    change_column_default :projects, :id, nil
    change_column_default :memberships, :id, nil
  end
end
