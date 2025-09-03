class User < ApplicationRecord
  has_many :time_entries
  validates :email, presence: true

  has_secure_password
  enum :role, { employee: 0, admin: 1 }
end
