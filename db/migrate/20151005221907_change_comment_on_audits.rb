class ChangeCommentOnAudits < ActiveRecord::Migration
  def up
    remove_column :audits, :comment
    add_column :audits, :comment, :jsonb
    add_index  :audits, :comment, using: :gin
  end

  def down
    remove_column :audits, :comment
    add_column :audits, :comment, :string
    remove_index  :audits, :comment
  end
end
