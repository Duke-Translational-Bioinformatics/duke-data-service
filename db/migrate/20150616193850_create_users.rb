class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :uuid
      t.string :etag
      t.string :email
      t.string :name

      t.timestamps null: false
    end
  end
end
