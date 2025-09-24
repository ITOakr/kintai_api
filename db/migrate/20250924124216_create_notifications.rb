class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.text :message
      t.boolean :read, default: false, null: false
      t.string :notification_type
      t.string :link_to

      t.timestamps
    end
  end
end
