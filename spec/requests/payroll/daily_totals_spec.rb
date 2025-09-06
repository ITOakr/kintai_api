require "rails_helper"

RSpec.describe "Payroll::DailyTotals", type: :request do
  let(:tz) { ActiveSupport::TimeZone["Asia/Tokyo"] }
  let(:date) { Date.parse("2025-09-06") }

  let!(:admin) do
    User.find_or_create_by!(email: "admin@example.com") do |u|
      u.password = "adminpass"
      u.role = :admin
      u.base_hourly_wage = 1200
      u.name = "管理者"
    end
  end

  let!(:emp1) do
    User.find_or_create_by!(email: "emp1@example.com") do |u|
      u.password = "emppass1"
      u.role = :employee
      u.base_hourly_wage = 1100
      u.name = "従業員A"
    end
  end

  let!(:emp2) do
    User.find_or_create_by!(email: "emp2@example.com") do |u|
      u.password = "emppass2"
      u.role = :employee
      u.base_hourly_wage = 1300
      u.name = "従業員B"
    end
  end

  def token_for(email:, password:)
    post "/auth/login", params: { email:, password: }
    JSON.parse(response.body)["token"]
  end

  # 各テストケースの前に、データベースをクリーンな状態に保つ
  before do
    TimeEntry.destroy_all
  end

  it "admin can view the daily total of multiple users" do
    # 従業員Aの打刻: 22:00-23:00（深夜60分）
    TimeEntry.create!(user_id: emp1.id, kind: :clock_in,  happened_at: tz.parse("#{date} 22:00"), source: "spec")
    TimeEntry.create!(user_id: emp1.id, kind: :clock_out, happened_at: tz.parse("#{date} 23:00"), source: "spec")

    # 従業員Bの打刻: 9:00-10:00（通常60分）
    TimeEntry.create!(user_id: emp2.id, kind: :clock_in,  happened_at: tz.parse("#{date} 09:00"), source: "spec")
    TimeEntry.create!(user_id: emp2.id, kind: :clock_out, happened_at: tz.parse("#{date} 10:00"), source: "spec")

    # 管理者としてログイン
    t = token_for(email: "admin@example.com", password: "adminpass")

    # daily_totalエンドポイントにリクエスト
    get "/v1/payroll/daily_total", params: { date: date.to_s }, headers: { "Authorization" => "Bearer #{t}" }

    # レスポンスの検証
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)

    # 日付の検証
    expect(body["date"]).to eq(date.to_s)

    # rowsの検証
    rows = body["rows"]
    expect(rows.count).to eq(2)

    # 従業員Aのデータ検証
    emp1_data = rows.find { |row| row["user_id"] == emp1.id }
    expect(emp1_data["work_minutes"]).to eq(60)
    expect(emp1_data["night_minutes"]).to eq(60)
    # 1100円/h → 通常 1100 * 1h = 1100、深夜ボーナス 1100*0.25*1h = 275 → 合計 1375
    expect(emp1_data["daily_wage"]).to eq(1375)

    # 従業員Bのデータ検証
    emp2_data = rows.find { |row| row["user_id"] == emp2.id }
    expect(emp2_data["work_minutes"]).to eq(60)
    expect(emp2_data["night_minutes"]).to eq(0)
    # 1300円/h → 通常 1300 * 1h = 1300 → 合計 1300
    expect(emp2_data["daily_wage"]).to eq(1300)

    # 合計金額の検証
    total_wage = emp1_data["daily_wage"] + emp2_data["daily_wage"]
    expect(body["total_daily_wage"]).to eq(total_wage)
  end
end
