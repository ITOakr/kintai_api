class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, null: false, default: 0 # 0: employee, 1: admin
    add_index :users, :role
  end
end
