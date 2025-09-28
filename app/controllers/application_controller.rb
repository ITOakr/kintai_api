class ApplicationController < ActionController::API
  attr_reader :current_user

  private

  # 認証を必須とするメソッド
  def authenticate!
    header = request.headers["Authorization"]
    # ヘッダーに"Authorization"がない場合はエラーを返す
    return render json: { error: "missing_token" }, status: :unauthorized if header.blank?
    token = header.split(" ").last
    payload = JsonWebToken.decode(token)
    @current_user = User.find(payload["sub"])
    # JWTのデコードやユーザーの検索に失敗した場合は「無効なトークン」としてエラーを返す
  rescue StandardError
    render json: { error: "invalid_token" }, status: :unauthorized
  end

  # 管理者権限を必須とするメソッド
  def require_admin!
    render json: { error: "forbidden" }, status: :forbidden unless current_user.admin?
  end

  # ログを作成する共通メソッド
  def create_admin_log(action:, target_user: nil, details: "")
    AdminLog.create!(
      admin_user: current_user,
      target_user: target_user,
      action: action,
      details: details
    )
  end
end
