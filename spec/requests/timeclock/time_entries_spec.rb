# spec/requests/timeclock/time_entries_spec.rb

require "rails_helper"

RSpec.describe "Timeclock::TimeEntries", type: :request do
  describe "POST /v1/timeclock/time_entries" do
    # 正常系のテスト
    context "パラメータが正常な場合" do
      it "新しい打刻が作成されること" do
        payload = {
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
    context "パラメータが不正な場合" do
      it "必須項目が欠けているため422エラーが返されること" do
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
end
