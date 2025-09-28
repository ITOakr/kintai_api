class AuthController < ApplicationController
  # POST /auth/login
  def login
    puts "--- RECEIVED PARAMS ---"
    puts params.to_unsafe_h.inspect
    user = User.find_by(email: login_params[:email])
    if user&.authenticate(login_params[:password])
      # 認証は成功したが，承認されていない場合は拒否
      unless user.status_active?
        return render json: { error: "このアカウントは管理者によってまだ認証されていません" }, status: :unauthorized
      end
      token = JsonWebToken.encode({ sub: user.id, exp: 24.hours.from_now.to_i })
      render json: { token: token, user: { id: user.id, email: user.email, name: user.name } }
    else
      render json: { error: "invalid_credentials" }, status: :unauthorized
    end
  end

  # GET /auth/me
  def me
    authenticate!
    render json: { id: current_user.id, email: current_user.email, name: current_user.name, role: current_user.role }
  end

  private

  def login_params
    params.require(:auth).permit(:email, :password)
  end
end
