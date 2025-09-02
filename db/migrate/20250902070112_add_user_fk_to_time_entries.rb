class AddUserFkToTimeEntries < ActiveRecord::Migration[8.0]
  def change
    add_index :time_entries, :user_id unless index_exists?(:time_entries, :user_id)
    # 既存データを壊さないためにまずは validate: false
    add_foreign_key :time_entries, :users, column: :user_id, validate: false
  end
end
