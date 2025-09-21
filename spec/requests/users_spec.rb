# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:admin) { User.create!(name: "管理者", email: "admin@example.com", password: "password", role: :admin, status: :active, base_hourly_wage: 1500) }
  let!(:employee) { User.create!(name: "従業員", email: "employee@example.com", password: "password", role: :employee, status: :active, base_hourly_wage: 1100) }
  let!(:pending_user) { User.create!(name: "承認待ちユーザー", email: "pending@example.com", password: "password", role: :employee, status: :pending, base_hourly_wage: 1000) }

  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  describe "PATCH /users/:id/approve" do
    it "ユーザーを承認すると、正しくAdminLogが作成されること" do
      token = login(admin)

      # AdminLogの数が1つ増えることを期待する
      expect {
        patch "/users/#{pending_user.id}/approve",
              params: { role: 'employee', base_hourly_wage: 1200 },
              headers: { "Authorization" => "Bearer #{token}" }
      }.to change(AdminLog, :count).by(1)

      expect(response).to have_http_status(:ok)

      # 作成された最新のログを取得して内容を検証
      log = AdminLog.last
      expect(log.action).to eq("ユーザー承認")
      expect(log.admin_user_id).to eq(admin.id)
      expect(log.target_user_id).to eq(pending_user.id)
      expect(log.details).to include("#{pending_user.name}さん")
    end
  end

  describe "PATCH /users/:id" do
    it "ユーザー情報を更新すると、正しくAdminLogが作成されること" do
      token = login(admin)

      expect {
        patch "/users/#{employee.id}",
              params: { role: 'admin', base_hourly_wage: 1200 }, # 権限と時給を変更
              headers: { "Authorization" => "Bearer #{token}" }
      }.to change(AdminLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      log = AdminLog.last
      expect(log.action).to eq("ユーザー情報更新")
      expect(log.details).to include("権限を「従業員」から「管理者」に変更しました。")
      expect(log.details).to include("時給を「1100円」から「1200円」に変更しました。")
    end

    it "ユーザー情報に変更がない場合は、ログが作成されないこと" do
      token = login(admin)

      # 変更がないリクエストを送っても、ログの数は変わらないはず
      expect {
        patch "/users/#{employee.id}",
              params: { role: 'employee', base_hourly_wage: 1100 }, # 変更なし
              headers: { "Authorization" => "Bearer #{token}" }
      }.not_to change(AdminLog, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /users/:id" do
    it "ユーザーを削除すると、正しくAdminLogが作成されること" do
      token = login(admin)

      expect {
        delete "/users/#{employee.id}",
               headers: { "Authorization" => "Bearer #{token}" }
      }.to change(AdminLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      log = AdminLog.last
      expect(log.action).to eq("ユーザー削除")
      expect(log.target_user_id).to eq(employee.id)
      expect(log.details).to include("#{employee.name}さん")
    end
  end
end
