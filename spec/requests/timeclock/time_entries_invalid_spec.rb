require "rails_helper"

RSpec.describe "Timeclock::TimeEntries invalid cases", type: :request do
  let(:day) { "2025-08-24" }
  let!(:user) { User.create!(id: 1, name: "Test", email: "test@example.com", password: "password", role: :employee, status: :active) }

  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  it "前回の出勤が終了していない場合，二重出勤は拒否されること" do
    token = login(user)
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("#{day} 09:00"), source: "web")

    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "clock_in",
      happened_at: "#{day}T20:00:00+09:00", source: "web"
    }, headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"].join).to match(/clock_in already exists and not closed yet for the day/)
  end

  it "事前の出勤がない場合，退勤は拒否されること" do
    token = login(user)
    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "clock_out",
      happened_at: "#{day}T18:00:00+09:00", source: "web"
    }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "すでに休憩中の場合，新たな休憩開始は拒否されること" do
    token = login(user)
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("#{day} 09:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_start,
                      happened_at: Time.zone.parse("#{day} 12:00"), source: "web")

    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "break_start",
      happened_at: "#{day}T12:10:00+09:00", source: "web"
    }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "事前の休憩開始がない場合，休憩終了は拒否されること" do
    token = login(user)
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("#{day} 09:00"), source: "web")

    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "break_end",
      happened_at: "#{day}T12:30:00+09:00", source: "web"
    }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
