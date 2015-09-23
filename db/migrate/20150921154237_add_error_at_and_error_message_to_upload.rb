class AddErrorAtAndErrorMessageToUpload < ActiveRecord::Migration
  def change
    add_column :uploads, :error_at, :datetime
    add_column :uploads, :error_message, :string
  end
end
