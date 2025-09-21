class AdminLogsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /admin_logs
  def index
    page = params.fetch(:page, 1).to_i
    per_page = params.fetch(:per_page, 20).to_i

    # ログを新しい順に取得し，関連するユーザー情報も一緒に取得
    logs = AdminLog.includes(:admin_user, :target_user)
                   .order(created_at: :desc)
                   .offset((page - 1) * per_page)
                   .limit(per_page)

    # 全体のログ件数を取得（ページネーション用）
    total_count = AdminLog.count

    render json: {
      logs: logs.map { |log|
        {
          id: log.id,
          created_at: log.created_at,
          admin_user_name: log.admin_user.name,
          target_user_name: log.target_user&.name, # target_userは存在しない場合がある
          action: log.action,
          details: log.details
        }
      },
      total_count: total_count,
      page: page,
      per_page: per_page
    }
  end
end
