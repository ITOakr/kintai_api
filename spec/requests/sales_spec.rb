# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales", type: :request do
  let(:tz) { ActiveSupport::TimeZone["Asia/Tokyo"] }
  let(:date) { Date.parse("2025-09-06") }

  # 管理者ユーザーをファクトリまたは直接作成
  let!(:admin) do
    User.find_or_create_by!(email: "admin@example.com") do |u|
      u.password = "adminpass"
      u.role = :admin
      u.base_hourly_wage = 1200
      u.name = "管理者"
    end
  end

  # ログイン用トークンを取得
  def token_for(email:, password:)
    post "/auth/login", params: { email:, password: }
    JSON.parse(response.body)["token"]
  end

  describe "GET /v1/sales" do
    let(:auth_headers) { { "Authorization" => "Bearer #{token_for(email: admin.email, password: 'adminpass')}" } }

    context "when a sale record exists for the date" do
      # テスト用の売上レコードを作成
      let!(:sale) { Sale.create!(date: date, amount_yen: 50000, note: "新商品セール") }

      it "returns the sale record for the date" do
        get "/v1/sales", params: { date: date.to_s }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)

        expect(body["date"]).to eq(date.to_s)
        expect(body["amount_yen"]).to eq(50000)
        expect(body["note"]).to eq("新商品セール")
      end
    end

    context "when a sale record does not exist for the date" do
      it "returns a record with amount_yen as nil" do
        get "/v1/sales", params: { date: date.to_s }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)

        expect(body["date"]).to eq(date.to_s)
        expect(body["amount_yen"]).to be_nil
        expect(body["note"]).to be_nil
      end
    end

    context "when the date parameter is invalid" do
      it "returns a bad request error" do
        get "/v1/sales", params: { date: "invalid-date" }, headers: auth_headers

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("invalid_date_format")
      end
    end
  end

  describe "PUT /v1/sales" do
    let(:auth_headers) { { "Authorization" => "Bearer #{token_for(email: admin.email, password: 'adminpass')}" } }

    context "when creating a new sale record (upsert)" do
      it "creates a new sale record" do
        put "/v1/sales", params: { date: date.to_s, amount_yen: 75000, note: "キャンペーン" }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)

        expect(body["date"]).to eq(date.to_s)
        expect(body["amount_yen"]).to eq(75000)
        expect(body["note"]).to eq("キャンペーン")

        # データベースにレコードが作成されたことを確認
        expect(Sale.find_by(date: date)).to be_present
      end
    end

    context "when updating an existing sale record (upsert)" do
      let!(:existing_sale) { Sale.create!(date: date, amount_yen: 10000, note: "既存データ") }

      it "updates the existing sale record" do
        put "/v1/sales", params: { date: date.to_s, amount_yen: 20000, note: "更新データ" }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)

        expect(body["amount_yen"]).to eq(20000)
        expect(body["note"]).to eq("更新データ")

        # データベースのレコードが更新されたことを確認
        updated_sale = Sale.find_by(date: date)
        expect(updated_sale.amount_yen).to eq(20000)
      end
    end

    context "when amount_yen is invalid" do
      it "returns an unprocessable_entity error" do
        put "/v1/sales", params: { date: date.to_s, amount_yen: -100, note: "マイナス金額" }, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["errors"]).to include("Amount yen must be greater than or equal to 0")
      end
    end
  end
end
