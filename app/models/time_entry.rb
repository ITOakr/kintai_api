class TimeEntry < ApplicationRecord
  enum :kind, { clock_in: 0, clock_out: 1, break_start: 2, break_end: 3 }

  validates :user_id, presence: true
  validates :happened_at, presence: true
  validates :source, presence: true
  validates :kind, presence: true
end
