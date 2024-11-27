class AddTotalPaidToDebtors < ActiveRecord::Migration[6.0]
  def change
    add_column :debtors, :total_paid, :decimal, default: 0.0
  end
end
