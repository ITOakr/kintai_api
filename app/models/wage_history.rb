class WageHistory < ApplicationRecord
  belongs_to :user

  validates :wage, presence: true, numericality: { greater_than: 0 }
  validates :effective_from, presence: true
  validate :effective_from_cannot_be_in_the_future
  validates :user_id, uniqueness: { scope: :effective_from, message: "should have only one wage per date" }

  private

  def effective_from_cannot_be_in_the_future
    if effective_from.present? && effective_from > Date.today
      errors.add(:effective_from, "can't be in the future")
    end
  end
end
