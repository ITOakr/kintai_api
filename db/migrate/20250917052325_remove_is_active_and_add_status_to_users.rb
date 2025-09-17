class RemoveIsActiveAndAddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    # is_activeカラムを削除
    remove_column :users, :is_active, :boolean

    # statusカラムを追加 (0: pending, 1: active, 2: deleted)
    add_column :users, :status, :integer, default: 0, null: false
  end
end
