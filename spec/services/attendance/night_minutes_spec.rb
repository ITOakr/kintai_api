require "rails_helper"

RSpec.describe "Attendance::Calculator.summarize_say" do
  let(:user_id) { 1 }
  let(:date) { Date.parse("2025-09-05") } # 金曜でも土曜でもOK

  before do
    # ユーザーが必要（FK制約）
    User.find_or_create_by!(id: user_id) do |u|
      u.email = "night@example.com"
      u.name  = "Night"
      u.password = "pass1234"
      u.role = :employee
      u.base_hourly_wage = 1100
    end
  end

  it "counts 22:00-23:00 as 60 minutes" do
    tz = ActiveSupport::TimeZone["Asia/Tokyo"]
    TimeEntry.create!(user_id: user_id, kind: :clock_in,  happened_at: tz.parse("#{date} 21:00"), source: "spec")
    TimeEntry.create!(user_id: user_id, kind: :clock_out, happened_at: tz.parse("#{date} 23:00"), source: "spec")

    expect(Attendance::Calculator.summarize_day(user_id: user_id, date: date).night_minutes).to eq(60)
  end

  it "counts 01:00-05:00 as 240 minutes" do
    tz = ActiveSupport::TimeZone["Asia/Tokyo"]
    TimeEntry.create!(user_id: user_id, kind: :clock_in,  happened_at: tz.parse("#{date} 01:00"), source: "spec")
    TimeEntry.create!(user_id: user_id, kind: :clock_out, happened_at: tz.parse("#{date} 06:00"), source: "spec")
    # 当日0-5の帯で該当するのは 01:00-05:00 = 240分
    expect(Attendance::Calculator.summarize_day(user_id: user_id, date: date).night_minutes).to eq(240)
  end

  it "excludes break within night window" do
    tz = ActiveSupport::TimeZone["Asia/Tokyo"]
    TimeEntry.create!(user_id: user_id, kind: :clock_in,     happened_at: tz.parse("#{date} 22:00"), source: "spec")
    TimeEntry.create!(user_id: user_id, kind: :break_start,  happened_at: tz.parse("#{date} 22:30"), source: "spec")
    TimeEntry.create!(user_id: user_id, kind: :break_end,    happened_at: tz.parse("#{date} 23:00"), source: "spec")
    TimeEntry.create!(user_id: user_id, kind: :clock_out,    happened_at: tz.parse("#{date} 23:30"), source: "spec")
    # 夜間 22:00-23:30 のうち 22:30-23:00 は休憩 → カウントされない
    expect(Attendance::Calculator.summarize_day(user_id: user_id, date: date).night_minutes).to eq(60)
  end
end
