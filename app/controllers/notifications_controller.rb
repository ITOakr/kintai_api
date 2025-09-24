class NotificationsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!
  before_action :set_notification, only: [ :update ]

  # GET /v1/notifications
  def index
    # 未読を上に、作成日の新しい順に並べて全て取得
    notifications = Notification.order(read: :asc, created_at: :desc)
    render json: notifications
  end

  # PATCH /v1/notifications/:id
  def update
    if @notification.update(read: true)
      render json: @notification
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_notification
    @notification = Notification.find_by(id: params[:id])
    unless @notification
      render json: { error: "Notification not found" }, status: :not_found
    end
  end
end
