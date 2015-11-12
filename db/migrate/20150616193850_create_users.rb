class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, id: :uuid do |t|
      t.string :username
      t.string :etag
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :display_name
      t.datetime :last_login_at

      t.timestamps null: false
    end
  end
end
