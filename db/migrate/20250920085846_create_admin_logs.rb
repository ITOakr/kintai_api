class CreateAdminLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_logs do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.references :target_user, null: true, foreign_key: { to_table: :users }
      t.string :action
      t.text :details

      t.timestamps
    end
  end
end
