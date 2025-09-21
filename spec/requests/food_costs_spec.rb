# spec/requests/food_costs_spec.rb
require 'rails_helper'

RSpec.describe "FoodCosts", type: :request do
  let!(:admin) { User.create!(name: "管理者", email: "admin@example.com", password: "password", role: :admin, status: :active) }
  let(:date) { Date.parse("2025-09-21") }

  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  describe "PUT /v1/food_costs" do
    let(:food_cost_params) do
      {
        date: date.to_s,
        food_costs: [
          { category: "meat", amount_yen: 10000 },
          { category: "drink", amount_yen: 5000 }
        ]
      }
    end

    context "食材費を新規登録する場合" do
      it "正しくログが作成されること" do
        token = login(admin)

        expect {
          put "/v1/food_costs", params: food_cost_params,
                                headers: { "Authorization" => "Bearer #{token}" }
        }.to change(AdminLog, :count).by(1)

        expect(response).to have_http_status(:ok)
        log = AdminLog.last
        expect(log.action).to eq("食材費登録")
        expect(log.details).to eq("#{date}の食材費を「15000円」で登録しました。")
      end
    end

    context "既存の食材費を更新する場合" do
      before do
        FoodCost.create!(date: date, category: "other", amount_yen: 3000)
      end

      it "正しくログが作成されること" do
        token = login(admin)

        expect {
          put "/v1/food_costs", params: food_cost_params,
                                headers: { "Authorization" => "Bearer #{token}" }
        }.to change(AdminLog, :count).by(1)

        expect(response).to have_http_status(:ok)
        log = AdminLog.last
        expect(log.action).to eq("食材費更新")
        expect(log.details).to eq("#{date}の食材費を「3000円」から「15000円」に更新しました。")
      end
    end
  end
end
