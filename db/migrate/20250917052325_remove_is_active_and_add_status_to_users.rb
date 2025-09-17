class RemoveIsActiveAndAddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status, :integer, default: 0, null: false

    remove_column :users, :is_active, :boolean
  end
end
