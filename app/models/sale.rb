class Sale < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :amount_yen, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
