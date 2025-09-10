class FoodCost < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :amount_yen, numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
