class CreateCommissions < ActiveRecord::Migration[7.0]
  def change
    create_table :commissions do |t|
      t.references :agent, null: false, foreign_key: true
      t.decimal :amount
      t.integer :month
      t.integer :year

      t.timestamps
    end
  end
end
