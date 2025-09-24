class CreateDailyFixedCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_fixed_costs do |t|
      t.date :date, null: false, index: { unique: true }
      t.integer :full_time_employee_count, null: false, default: 0
      t.integer :daily_wage_per_employee, null: false, default: 10800

      t.timestamps
    end
  end
end
