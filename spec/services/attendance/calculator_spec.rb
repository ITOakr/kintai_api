# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attendance::Calculator do
  let(:date1) { Date.parse("2025-08-21") }
  let(:date2) { Date.parse("2025-08-22") }
  before do
    User.find_or_create_by!(id: 1) { |u| u.name = "Test"; u.email = "test@example.com"; u.password = "password" }
  end

  it "打刻が一件も存在しない場合、'not_started'が返されること" do
    r = described_class.summarize_day(user_id: 1, date: date1)
    expect(r.status).to eq("not_started")
    expect(r.work_minutes).to eq(0)
  end

  it "出勤の打刻だけが存在する場合、'open'が返されること" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, date: date1)
    expect(r.start_at).to be_present
    expect(r.end_at).to be_nil
    expect(r.work_minutes).to eq(0)
    expect(r.status).to eq("open")
  end

  it "出勤と退勤の両方が存在する場合、'closed'ステータスと正しい勤務時間が返されること" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out,
                      happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, date: date1)
    expect(r.work_minutes).to eq(9 * 60)
    expect(r.status).to eq("closed")
  end

  it "出勤はないが他の打刻が存在する場合、'closed'ステータスが返されること" do
    # バリデーションをスキップして不整合データを注入
    TimeEntry.new(user_id: 1, kind: :clock_out,
                  happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web").save!(validate: false)

    r = described_class.summarize_day(user_id: 1, date: date1)
    expect(r.status).to eq("closed")
    expect(r.work_minutes).to eq(0)
  end

  it "複数の出勤・退勤が存在する場合、最初の出勤と最後の退勤が使われること" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,  happened_at: Time.zone.parse("2025-08-21 08:55"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-21 17:50"), source: "web")
    # 最後のclock_outを少し後ろに
    TimeEntry.new(user_id: 1, kind: :clock_out,
                  happened_at: Time.zone.parse("2025-08-21 18:05"), source: "web").save!(validate: false)

    r = described_class.summarize_day(user_id: 1, date: date1)
    expect(r.start_at.iso8601).to include("08:55")
    expect(r.end_at.iso8601).to include("18:05")
  end

  it "休憩時間が正しく控除され、勤務時間外の休憩は無視されること" do
    # 勤務 10:00-19:00
    TimeEntry.create!(user_id: 1, kind: :clock_in,  happened_at: Time.zone.parse("2025-08-22 10:00"), source: "web")
    # 休憩ペア1（勤務内）
    TimeEntry.create!(user_id: 1, kind: :break_start, happened_at: Time.zone.parse("2025-08-22 12:10"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_end,   happened_at: Time.zone.parse("2025-08-22 12:40"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-22 19:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, date: date2)
    expect(r.break_minutes).to eq(30)      # 12:10-12:40 の30分だけ
    expect(r.work_minutes).to  eq(540 - 30)
    expect(r.status).to eq("closed")
  end
end
