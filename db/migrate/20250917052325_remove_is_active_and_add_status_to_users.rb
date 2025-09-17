class RemoveIsActiveAndAddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    # is_activeカラムを削除
    if column_exists?(:users, :is_active)
      remove_column :users, :is_active, :boolean
    end

    # statusカラムを追加 (0: pending, 1: active, 2: deleted)
    unless column_exists?(:users, :status)
      add_column :users, :status, :integer, default: 0, null: false
    end
  end
end
