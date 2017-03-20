class CreateJobTransactions < ActiveRecord::Migration
  def change
    create_table :job_transactions do |t|
      t.string :transactionable_type
      t.uuid :transactionable_id
      t.string :key
      t.string :state

      t.timestamps null: false
    end
  end
end
