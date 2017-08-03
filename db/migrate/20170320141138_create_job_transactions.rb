class CreateJobTransactions < ActiveRecord::Migration[4.2]
  def change
    create_table :job_transactions do |t|
      t.string :transactionable_type
      t.uuid :transactionable_id
      t.string :request_id
      t.string :key
      t.string :state

      t.timestamps null: false
    end
  end
end
