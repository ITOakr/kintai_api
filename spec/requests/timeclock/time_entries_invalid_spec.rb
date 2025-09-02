require "rails_helper"

RSpec.describe "Timeclock::TimeEntries invalid cases", type: :request do
  let(:day) { "2025-08-24" }

  before do
    User.find_or_create_by!(id: 1) { |u| u.name = "Test"; u.email = "test@example.com" }
  end
  it "前回の出勤が終了していない場合，二重出勤は拒否されること" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("#{day} 09:00"), source: "web")

    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "clock_in",
      happened_at: "#{day}T20:00:00+09:00", source: "web"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"].join).to match(/not closed/)
  end

  it "事前の出勤がない場合，退勤は拒否されること" do
    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "clock_out",
      happened_at: "#{day}T18:00:00+09:00", source: "web"
    }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "すでに休憩中の場合，新たな休憩開始は拒否されること" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("#{day} 09:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_start,
                      happened_at: Time.zone.parse("#{day} 12:00"), source: "web")

    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "break_start",
      happened_at: "#{day}T12:10:00+09:00", source: "web"
    }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "事前の休憩開始がない場合，休憩終了は拒否されること" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("#{day} 09:00"), source: "web")

    post "/v1/timeclock/time_entries", params: {
      user_id: 1, kind: "break_end",
      happened_at: "#{day}T12:30:00+09:00", source: "web"
    }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
