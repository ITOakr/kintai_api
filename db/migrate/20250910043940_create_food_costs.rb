class CreateFoodCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :food_costs do |t|
      t.date :date, null: false, index: { unique: true }
      t.integer :amount_yen, null: false, default: 0
      t.string :note

      t.timestamps
    end
    add_check_constraint :food_costs, "amount_yen >= 0", name: "chk_food_cost_amount_nonneg"
  end
end
