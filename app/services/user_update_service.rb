class UserUpdateService
  attr_reader :errors
  def initialize(user, params, admin_user)
    @user = user
    @params = params
    @admin_user = admin_user
    @errors = []
  end

  def perform
    user_before_update = @user.dup
    ActiveRecord::Base.transaction do
      @user.update!(@params)
      details = create_change_details(user_before_update)
      update_wage_history_if_changed(user_before_update)
      create_log_if_changed(details)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    false
  end

  private

  def create_change_details(user_before_update)
    details = []
    if user_before_update.role != @user.role
      details << "権限を「#{user_before_update.role_i18n}」から「#{@user.role_i18n}」に変更しました。"
    end
    if user_before_update.base_hourly_wage != @user.base_hourly_wage
      details << "時給を「#{user_before_update.base_hourly_wage}円」から「#{@user.base_hourly_wage}円」に変更しました。"
    end
    details
  end

  def update_wage_history_if_changed(user_before_update)
    return if user_before_update.base_hourly_wage == @user.base_hourly_wage
    history = WageHistory.find_or_initialize_by(
      user: @user,
      effective_from: Date.current
    )
    history.wage = @user.base_hourly_wage
    history.save!
  end

  def create_log_if_changed(details)
    return if details.empty?
    AdminLog.create!(
      admin_user: @admin_user,
      action: "ユーザー情報更新",
      target_user: @user,
      details: "#{@user.name}さんの情報を更新しました。\n" + details.join("\n")
    )
  end
end
