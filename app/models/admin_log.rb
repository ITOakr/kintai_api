class AdminLog < ApplicationRecord
  belongs_to :admin_user, class_name: "User"
  belongs_to :target_user, class_name: "User", optional: true
end
