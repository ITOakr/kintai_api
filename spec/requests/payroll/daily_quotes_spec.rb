require "rails_helper"

RSpec.describe "Payroll::DailyQuotes", type: :request do
  let(:tz) { ActiveSupport::TimeZone["Asia/Tokyo"] }
  let(:date) { Date.parse("2025-09-06") }

  let!(:admin) do
    User.find_or_create_by!(email: "admin@example.com") do |u|
      u.password = "adminpass"
      u.role = :admin
      u.base_hourly_wage = 1200
      u.name = "Admin"
    end
  end

  let!(:emp) do
    User.find_or_create_by!(email: "emp@example.com") do |u|
      u.password = "emppass"
      u.role = :employee
      u.base_hourly_wage = 1100
      u.name = "Emp"
    end
  end

  def token_for(email:, password:)
    post "/auth/login", params: { email:, password: }
    JSON.parse(response.body)["token"]
  end

  it "returns daily quote for me" do
    # 22:00-23:00（深夜60分）勤務
    TimeEntry.create!(user_id: emp.id, kind: :clock_in,  happened_at: tz.parse("#{date} 22:00"), source: "spec")
    TimeEntry.create!(user_id: emp.id, kind: :clock_out, happened_at: tz.parse("#{date} 23:00"), source: "spec")

    t = token_for(email: "emp@example.com", password: "emppass")
    get "/v1/payroll/me/daily_quote", params: { date: date.to_s }, headers: { "Authorization" => "Bearer #{t}" }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["work_minutes"]).to eq(60)
    expect(body["night_minutes"]).to eq(60)
    # 1100円/h → 通常 1100 * 1h = 1100、夜間ボーナス 1100*0.25*1h = 275 → 合計 1375
    expect(body["daily_wage"]).to eq(1375)
  end

  it "allows admin to view other user" do
    t = token_for(email: "admin@example.com", password: "adminpass")
    get "/v1/payroll/user/daily_quote", params: { user_id: emp.id, date: date.to_s }, headers: { "Authorization" => "Bearer #{t}" }
    expect(response).to have_http_status(:ok)
  end
end
