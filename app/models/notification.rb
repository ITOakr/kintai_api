class Notification < ApplicationRecord
  enum :notification_type, {
    user_approval_request: 0, # 新規登録申請
    f_l_ratio_warning: 1      # FL比率の警告
  }
end
