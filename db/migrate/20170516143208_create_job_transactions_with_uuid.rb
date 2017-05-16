class CreateJobTransactionsWithUuid < ActiveRecord::Migration[5.0]
  def up
    drop_table :job_transactions
    create_table :job_transactions, id: :uuid do |t|
      t.string :transactionable_type
      t.uuid :transactionable_id
      t.string :request_id
      t.string :key
      t.string :state

      t.timestamps null: false
    end
  end

  def down
    drop_table :job_transactions
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
