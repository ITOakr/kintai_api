class AddIsActiveToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_active, :boolean, default: false, null: false
  end
end
