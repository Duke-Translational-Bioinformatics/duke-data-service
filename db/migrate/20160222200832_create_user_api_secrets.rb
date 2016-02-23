class CreateUserApiSecrets < ActiveRecord::Migration
  def change
    create_table :user_api_secrets do |t|
      t.uuid :user_id
      t.string :key

      t.timestamps null: false
    end
  end
end
