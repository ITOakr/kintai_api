# spec/requests/sales_spec.rb
require 'rails_helper'

RSpec.describe "Sales", type: :request do
  let!(:admin) { User.create!(name: "管理者", email: "admin@example.com", password: "password", role: :admin, status: :active) }
  let(:date) { Date.parse("2025-09-20") }

  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  describe "PUT /v1/sales" do
    context "売上を新規登録する場合" do
      it "正しくログが作成されること" do
        token = login(admin)

        expect {
          put "/v1/sales", params: { date: date.to_s, amount_yen: 50000, note: "新規売上" },
                           headers: { "Authorization" => "Bearer #{token}" }
        }.to change(AdminLog, :count).by(1)

        expect(response).to have_http_status(:ok)
        log = AdminLog.last
        expect(log.action).to eq("売上登録")
        expect(log.details).to eq("#{date}の売上を「50000円」で登録しました。")
      end
    end

    context "既存の売上を更新する場合" do
      let!(:sale) { Sale.create!(date: date, amount_yen: 50000) }

      it "正しくログが作成されること" do
        token = login(admin)

        expect {
          put "/v1/sales", params: { date: date.to_s, amount_yen: 60000, note: "売上更新" },
                           headers: { "Authorization" => "Bearer #{token}" }
        }.to change(AdminLog, :count).by(1)

        expect(response).to have_http_status(:ok)
        log = AdminLog.last
        expect(log.action).to eq("売上更新")
        expect(log.details).to eq("#{date}の売上を「50000円」から「60000円」に更新しました。")
      end
    end
  end
end
