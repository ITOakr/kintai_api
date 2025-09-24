class DailyFixedCost < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :full_time_employee_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :daily_wage_per_employee, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
