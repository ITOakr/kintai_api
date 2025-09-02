class ApplicationController < ActionController::API
   attr_reader :current_user

  private

  def authenticate!
    header = request.headers["Authorization"]
    return render json: { error: "missing_token" }, status: :unauthorized if header.blank?

    token = header.split(" ").last
    payload = JsonWebToken.decode(token)
    @current_user = User.find(payload["sub"])
  rescue JWT::ExpiredSignature
    render json: { error: "token_expired" }, status: :unauthorized
  rescue StandardError
    render json: { error: "invalid_token" }, status: :unauthorized
  end

  # 認証は不要だが、トークンがあれば current_user をセット（POST打刻で使う）
  def set_current_user_if_token_present
    header = request.headers["Authorization"]
    return if header.blank?

    token = header.split(" ").last
    payload = JsonWebToken.decode(token)
    @current_user = User.find(payload["sub"])
  rescue StandardError
    # 何もしない（任意トークン）
  end
end
