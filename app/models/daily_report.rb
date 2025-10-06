# app/models/daily_report.rb
class DailyReport < ApplicationRecord
  validates :date, presence: true, uniqueness: true
end
