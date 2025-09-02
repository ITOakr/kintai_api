class User < ApplicationRecord
  has_many :time_entries
  validates :email, presence: true

  has_secure_password
end
