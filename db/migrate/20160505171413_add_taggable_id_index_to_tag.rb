class AddTaggableIdIndexToTag < ActiveRecord::Migration
  def change
    add_index :tags, :taggable_id
  end
end
