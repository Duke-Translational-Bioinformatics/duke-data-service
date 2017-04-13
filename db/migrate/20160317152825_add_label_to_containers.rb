class AddLabelToContainers < ActiveRecord::Migration[4.2]
  def change
    add_column :containers, :label, :string
  end
end
