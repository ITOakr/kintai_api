class UserApprovalService
  attr_reader :errors
  def initialize(user, params, admin_user)
    @user = user
    @params = params
    @admin_user = admin_user
    @errors = []
  end

  def perform
    ActiveRecord::Base.transaction do
      # ユーザー情報の更新
      @user.update!(@params.merge(status: :active))

      # 時給履歴を作成
      WageHistory.create!(
        user: @user,
        wage: @user.base_hourly_wage,
        effective_from: Date.current
      )

      # 管理者ログを作成
      AdminLog.create!(
        admin_user: @admin_user,
        action: "ユーザー承認",
        target_user: @user,
        details: "#{@user.name}さんを承認しました。"
      )
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    false
  end
end
