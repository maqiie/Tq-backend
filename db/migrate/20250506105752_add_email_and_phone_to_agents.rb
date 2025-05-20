class AddEmailAndPhoneToAgents < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :email, :string
    add_column :agents, :phone, :string
  end
end
