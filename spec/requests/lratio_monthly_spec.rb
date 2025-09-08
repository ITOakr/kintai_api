# spec/requests/lratio_monthly_spec.rb
require "rails_helper"

RSpec.describe "LRatio monthly", type: :request do
  let(:tz) { ActiveSupport::TimeZone["Asia/Tokyo"] }
  let(:year) { 2025 }
  let(:month) { 9 }
  let(:d1) { Date.new(year, month, 1) }
  let(:d2) { Date.new(year, month, 2) }

  let!(:admin) do
    User.find_or_create_by!(email: "admin@example.com") do |u|
      u.password = "adminpass"
      u.role = :admin
      u.base_hourly_wage = 1200
      u.name = "管理者"
    end
  end

  let!(:emp) do
    User.find_or_create_by!(email: "emp@example.com") do |u|
      u.password = "emppass"
      u.role = :employee
      u.base_hourly_wage = 1000
      u.name = "従業員"
    end
  end

  def token_for(email:, password:)
    post "/auth/login", params: { email:, password: }
    JSON.parse(response.body)["token"]
  end

  before do
    TimeEntry.destroy_all
    Sale.destroy_all
    # d1: 2h勤務, 売上1万円 → wage=2000, ratio=0.2
    TimeEntry.create!(user_id: emp.id, kind: :clock_in,  happened_at: tz.parse("#{d1} 09:00"), source: "spec")
    TimeEntry.create!(user_id: emp.id, kind: :clock_out, happened_at: tz.parse("#{d1} 11:00"), source: "spec")
    Sale.create!(date: d1, amount_yen: 10000)
    # d2: 1h勤務, 売上なし → wage=1000, ratio=nil
    TimeEntry.create!(user_id: emp.id, kind: :clock_in,  happened_at: tz.parse("#{d2} 10:00"), source: "spec")
    TimeEntry.create!(user_id: emp.id, kind: :clock_out, happened_at: tz.parse("#{d2} 11:00"), source: "spec")
  end

  it "returns monthly days and totals" do
    t = token_for(email: "admin@example.com", password: "adminpass")
    get "/v1/l_ratio/monthly", params: { year:, month: }, headers: { "Authorization" => "Bearer #{t}" }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["year"]).to eq(year)
    expect(body["month"]).to eq(month)

    d1row = body["days"].find { |x| x["date"] == d1.to_s }
    d2row = body["days"].find { |x| x["date"] == d2.to_s }

    expect(d1row["total_daily_wage"]).to eq(2000)
    expect(d1row["daily_sales"]).to eq(10000)
    expect(d1row["l_ratio"]).to eq(0.2)

    expect(d2row["total_daily_wage"]).to eq(1000)
    expect(d2row["daily_sales"]).to be_nil
    expect(d2row["l_ratio"]).to be_nil

    expect(body["monthly_sales"]).to eq(10000)
    expect(body["monthly_wage"]).to eq(3000)
    expect(body["monthly_l_ratio"]).to eq(0.3)
  end
end
