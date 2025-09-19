class FoodCost < ApplicationRecord
  enum category: {
    meat: 0,
    ingredient: 1,
    drink: 2,
    other: 3
  }

  validates :date, presence: true
  validates :amount_yen, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :category, presence: true, inclusion: { in: categories.keys }
end
