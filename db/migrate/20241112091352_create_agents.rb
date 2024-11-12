class CreateAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :agents do |t|
      t.string :name
      t.string :type_of_agent
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
