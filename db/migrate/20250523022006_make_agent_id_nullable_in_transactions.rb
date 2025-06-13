class MakeAgentIdNullableInTransactions < ActiveRecord::Migration[6.1]
  def change
    change_column_null :transactions, :agent_id, true
  end
end
