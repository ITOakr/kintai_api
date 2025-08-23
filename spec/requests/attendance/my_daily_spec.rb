require "rails_helper"

RSpec.describe "Attendance::Daily", type: :request do
  describe "GET /v1/attendance/my/daily" do
    # 正常なデータがある場合のテスト
    context "正常なデータが存在する場合" do
      it "出勤と退勤の両方がある場合、正しいサマリと'closed'ステータスを返す" do
        # 準備: ユーザーID 1 の出勤・退勤データを作成
        TimeEntry.create!(user_id: 1, kind: :clock_in, happened_at: Time.zone.parse("2025-08-22 09:00"), source: "web")
        TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-22 18:00"), source: "web")

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        expect(body["status"]).to eq("closed")
        expect(body["totals"]["work"]).to eq(540) # 9時間 = 540分
      end

      it "出勤のみの場合、'open'ステータスを返す" do
        TimeEntry.create!(user_id: 1, kind: :clock_in, happened_at: Time.zone.parse("2025-08-22 09:00"), source: "web")

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        expect(body["status"]).to eq("open")
        expect(body["actual"]["end"]).to be_nil
      end
    end

    # データが不整合または存在しない場合のテスト
    context "データが不整合または存在しない場合" do
      it "その日の打刻が一件もない場合、'not_started'ステータスを返す" do
        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        # 期待するステータスが "open" から "not_started" に変わる
        expect(body["status"]).to eq("not_started")
      end

      it "退勤のみが存在する場合、'inconsistent_data'ステータスを返す" do
        TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-22 18:00"), source: "web")

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        # 期待するステータスが "closed" から "inconsistent_data" に変わる
        expect(body["status"]).to eq("inconsistent_data")
      end
    end

    # パラメータが不正または欠損している場合のテスト
    context "パラメータが不正または欠損している場合" do
      it "dateパラメータが欠損している場合、400エラーを返す" do
        get "/v1/attendance/my/daily", params: { user_id: 1 }
        expect(response).to have_http_status(:bad_request)
      end
    end

    it "returns not_started when no entries" do
      get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-21" }
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("not_started")
      expect(body["totals"]["work"]).to eq(0)
    end

    it "returns inconsistent_data when only clock_out exists" do
      TimeEntry.create!(user_id: 1, kind: :clock_out,
                        happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web")
      get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-21" }
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("inconsistent_data")
      expect(body["actual"]["start"]).to be_nil
      expect(body["actual"]["end"]).to include("2025-08-21T18:00")
      expect(body["totals"]["work"]).to eq(0)
    end
  end
end
