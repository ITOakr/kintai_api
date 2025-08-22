class CreateTimeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :time_entries do |t|
      t.integer :user_id, null: false, index: true
      t.integer :kind
      t.datetime :happened_at, null: false, index: true
      t.string :source, null: false

      t.timestamps
    end
  end
end
