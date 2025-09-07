require "rails_helper"

RSpec.describe "Ratio::Daily", type: :request do
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

  before { TimeEntry.destroy_all }

  it "returns ratio when sales exists" do
    # 労働 2h（通常）→ wage = 1000*2 = 2000
    TimeEntry.create!(user_id: emp.id, kind: :clock_in,  happened_at: tz.parse("#{date} 09:00"), source: "spec")
    TimeEntry.create!(user_id: emp.id, kind: :clock_out, happened_at: tz.parse("#{date} 11:00"), source: "spec")
    Sale.create!(date: date, amount_yen: 10000)

    t = token_for(email: "admin@example.com", password: "adminpass")
    get "/v1/l_ratio/daily", params: { date: date.to_s }, headers: { "Authorization" => "Bearer #{t}" }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["total_daily_wage"]).to eq(2000)
    expect(body["daily_sales"]).to eq(10000)
    expect(body["l_ratio"]).to eq(0.2)
  end

  it "ratio is null when sales missing" do
    t = token_for(email: "admin@example.com", password: "adminpass")
    get "/v1/l_ratio/daily", params: { date: date.to_s }, headers: { "Authorization" => "Bearer #{t}" }
    body = JSON.parse(response.body)
    expect(body["l_ratio"]).to be_nil
  end
end
