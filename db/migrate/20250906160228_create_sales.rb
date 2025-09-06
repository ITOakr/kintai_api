class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.date :date, null: false
      t.integer :amount_yen, null: false, default: 0
      t.string :note

      t.timestamps
    end
    add_index :sales, :date, unique: true
    add_check_constraint :sales, "amount_yen >= 0", name: "chk_amount_nonneg"
  end
end
