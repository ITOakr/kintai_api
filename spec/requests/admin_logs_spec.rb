# spec/requests/admin_logs_spec.rb
require 'rails_helper'

RSpec.describe "AdminLogs", type: :request do
  # テスト用のユーザーを事前に作成
  let!(:admin) { User.create!(name: "管理者", email: "admin@example.com", password: "password", role: :admin, status: :active) }
  let!(:employee) { User.create!(name: "従業員", email: "employee@example.com", password: "password", role: :employee, status: :active) }

  # テスト用のログデータを事前に作成
  let!(:log1) { AdminLog.create!(admin_user: admin, action: "ユーザー承認", details: "テストユーザー1を承認", created_at: 1.day.ago) }
  let!(:log2) { AdminLog.create!(admin_user: admin, action: "売上更新", details: "2025-09-20の売上を更新", created_at: Time.current) }

  # ログインするためのヘルパーメソッド
  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  describe "GET /v1/admin_logs" do
    context "管理者がアクセスした場合" do
      it "ログの一覧を正しく取得できること" do
        token = login(admin)
        get "/v1/admin_logs", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # 2件のログが返ってくることを確認
        expect(json["logs"].size).to eq(2)
        # 新しい順に並んでいることを確認
        expect(json["logs"][0]["action"]).to eq("売上更新")
        # ページネーション情報が含まれていることを確認
        expect(json["total_count"]).to eq(2)
      end
    end

    context "従業員がアクセスした場合" do
      it "アクセスが拒否されること" do
        token = login(employee)
        get "/v1/admin_logs", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "ログインしていない場合" do
      it "アクセスが拒否されること" do
        get "/v1/admin_logs"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
