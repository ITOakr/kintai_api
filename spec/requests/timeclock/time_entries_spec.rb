# spec/requests/timeclock/time_entries_spec.rb

require "rails_helper"

RSpec.describe "Timeclock::TimeEntries", type: :request do
  describe "POST /v1/timeclock/time_entries" do
    # 正常系のテスト
    context "with valid parameters" do
      it "creates a new TimeEntry" do
        payload = {
          # Userモデルを使わないため、user_idを直接「1」として指定します
          user_id: 1,
          kind: "clock_in",
          happened_at: "2025-08-22T09:00:00+09:00",
          source: "web"
        }
        post "/v1/timeclock/time_entries", params: payload
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["kind"]).to eq("clock_in")
      end
    end

    # 異常系のテスト
    context "with invalid parameters" do
      it "returns 422 for missing required fields" do
        # 必須項目である user_id をわざと含めずにリクエストを送ります
        payload = {
          kind: "clock_in",
          happened_at: "2025-08-22T09:00:00+09:00",
          source: "web"
        }
        post "/v1/timeclock/time_entries", params: payload
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /v1/timeclock/time_entries" do
    # 正常系のテスト
    context "with valid parameters" do
      it "lists entries for the date" do
        # テストデータ作成時も、user_idを直接指定します
        TimeEntry.create!(
          user_id: 1,
          kind: "clock_in",
          happened_at: Time.zone.parse("2025-08-22 09:00"),
          source: "web"
        )
        # 検索時も、user_idを直接指定します
        get "/v1/timeclock/time_entries", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)
        arr = JSON.parse(response.body)
        expect(arr.size).to eq(1)
        expect(arr.first["kind"]).to eq("clock_in")
      end
    end

    # 異常系のテスト
    context "with invalid parameters" do
      it "returns 400 when user_id is missing" do
        # 必須パラメータである user_id を含めずにリクエストを送ります
        get "/v1/timeclock/time_entries", params: { date: "2025-08-22" }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
