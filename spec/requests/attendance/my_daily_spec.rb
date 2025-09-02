# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Attendance::Daily", type: :request do
  before do
    User.find_or_create_by!(id: 1) { |u| u.name = "Test"; u.email = "test@example.com" }
  end
  describe "GET /v1/attendance/my/daily" do
    context "正常なデータが存在する場合" do
      it "出勤と退勤の両方がある場合、正しいサマリと'closed'ステータスを返す" do
        TimeEntry.create!(user_id: 1, kind: :clock_in,
                          happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")
        TimeEntry.create!(user_id: 1, kind: :clock_out,
                          happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web")

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-21" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["actual"]["start"]).to include("2025-08-21T09:00")
        expect(body["actual"]["end"]).to   include("2025-08-21T18:00")
        expect(body["totals"]["work"]).to  eq(9 * 60) # 540分
        expect(body["status"]).to eq("closed")
      end

      it "出勤のみの場合、'open'ステータスを返す" do
        TimeEntry.create!(user_id: 1, kind: :clock_in,
                          happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-21" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["actual"]["end"]).to be_nil
        expect(body["totals"]["work"]).to eq(0)
        expect(body["status"]).to eq("open")
      end

      it "休憩がある場合、breakを控除して返す" do
        TimeEntry.create!(user_id: 1, kind: :clock_in,
                          happened_at: Time.zone.parse("2025-08-23 09:00"), source: "web")
        TimeEntry.create!(user_id: 1, kind: :break_start,
                          happened_at: Time.zone.parse("2025-08-23 12:00"), source: "web")
        TimeEntry.create!(user_id: 1, kind: :break_end,
                          happened_at: Time.zone.parse("2025-08-23 12:30"), source: "web")
        TimeEntry.create!(user_id: 1, kind: :clock_out,
                          happened_at: Time.zone.parse("2025-08-23 18:00"), source: "web")

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-23" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["totals"]["break"]).to eq(30)
        expect(body["totals"]["work"]).to  eq(540 - 30) # 510分
        expect(body["status"]).to eq("closed")
      end
    end

    context "データが不整合または存在しない場合" do
      it "その日の打刻が一件もない場合、'not_started'を返す" do
        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("not_started")
      end

      it "退勤のみが存在する場合、'inconsistent_data'を返す（検証スキップで不整合データを挿入）" do
        TimeEntry.new(user_id: 1, kind: :clock_out,
                      happened_at: Time.zone.parse("2025-08-22 18:00"), source: "web")
                 .save!(validate: false)

        get "/v1/attendance/my/daily", params: { user_id: 1, date: "2025-08-22" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("inconsistent_data")
      end
    end
  end
end
