class HardenTimeEntriesConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :time_entries, :user_id, false
    change_column_null :time_entries, :happened_at, false
    change_column_null :time_entries, :source, false
    change_column_null :time_entries, :kind, false

    add_index :time_entries, [ :user_id, :happened_at ]
    # enum: { clock_in:0, clock_out:1, break_start:2, break_end:3 }
    add_check_constraint :time_entries, "kind IN (0, 1, 2, 3)", name: "chk_time_entries_kind_enum"
  end
end
