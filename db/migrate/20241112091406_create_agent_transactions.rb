class CreateAgentTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_transactions do |t|
      t.references :agent, null: false, foreign_key: true
      t.decimal :opening_balance
      t.decimal :closing_balance

      t.timestamps
    end
  end
end
