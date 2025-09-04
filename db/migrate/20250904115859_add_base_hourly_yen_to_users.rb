class AddBaseHourlyYenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :base_hourly_wage, :integer, null: false, default: 0

    add_check_constraint :users,
    "base_hourly_wage >= 0",
    name: "base_hourly_wage_non_negative"
  end
end
