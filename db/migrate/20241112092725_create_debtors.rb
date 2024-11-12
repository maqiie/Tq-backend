class CreateDebtors < ActiveRecord::Migration[7.0]
  def change
    create_table :debtors do |t|
      t.string :name
      t.decimal :debt_amount
      t.references :agent, null: false, foreign_key: true

      t.timestamps
    end
  end
end
