class AddLabelToContainers < ActiveRecord::Migration
  def change
    add_column :containers, :label, :string
  end
end
