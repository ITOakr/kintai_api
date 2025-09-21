class UsersController < ApplicationController
  before_action :authenticate!, only: [ :pending, :approve, :index, :update, :destroy ]
  before_action :require_admin!, only: [ :pending, :approve, :index, :update, :destroy ]
  before_action :set_user, only: [ :approve, :update, :destroy ]

  # GET /users
  def index
    @users = User.status_active.order(:id)
    render json: @users.as_json(only: [ :id, :name, :email, :role, :base_hourly_wage ]), status: :ok
  end

  # POST /users/signup
  def signup
    user = User.new(user_params)
    user.status = :pending
    if user.save
      render json: { message: "ユーザー登録の申請を受け付けました。管理者の承認をお待ちください。" }, status: :created
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /users/pending
  def pending
    @pending_users = User.status_pending
    render json: @pending_users, status: :ok
  end

  # PATCH /users/:id/approve
  def approve
    if @user.update(approve_params)
      create_admin_log(
        action: "ユーザー承認",
        target_user: @user,
        details: "#{@user.name}さんを承認しました。"
      )
      render json: { message: "#{@user.name}さんを承認しました。" }, status: :ok
    else
      render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /users/:id
  def update
    user_before_update = @user.dup
    if @user.update(user_update_params)
      details = []
      if user_before_update.role != @user.role
        details << "権限を「#{user_before_update.role_i18n}」から「#{@user.role_i18n}」に変更しました。"
      end
      if user_before_update.base_hourly_wage != @user.base_hourly_wage
        details << "時給を「#{user_before_update.base_hourly_wage}円」から「#{@user.base_hourly_wage}円」に変更しました。"
      end
      if details.any?
        create_admin_log(
          action: "ユーザー情報更新",
          target_user: @user,
          details: "#{@user.name}さんの情報を更新しました。\n " + details.join("\n")
        )
      end
      render json: { message: "#{@user.name}さんの情報を更新しました。" }, status: :ok
    else
      render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    begin
      @user.update!(status: :deleted)
      create_admin_log(
        action: "ユーザー削除",
        target_user: @user,
        details: "#{@user.name}さんを削除しました。"
      )
      render json: { message: "#{@user.name}さんを削除しました。" }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def approve_params
    params.permit(:role, :base_hourly_wage).merge(status: :active)
  end

  def user_update_params
    params.permit(:role, :base_hourly_wage)
  end

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end

  def set_user
    @user = User.find(params[:id])
  end
end
