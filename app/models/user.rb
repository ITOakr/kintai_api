class User < ApplicationRecord
  has_many :time_entries
  validates :email, presence: true
end
