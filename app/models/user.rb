class User < ApplicationRecord
  has_many :time_entries
  validates :email, presence: true

  has_secure_password
  enum :role, { employee: 0, admin: 1 }

  enum :status, { pending: 0, active: 1, deleted: 2 }, prefix: true

  validates :base_hourly_wage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def role_i18n
    I18n.t("activerecord.attributes.user.roles.#{role}")
  end
end
