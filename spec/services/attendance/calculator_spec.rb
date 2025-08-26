require "rails_helper"

RSpec.describe Attendance::Calculator do
  let(:date) { Date.parse("2025-08-21") }

  it "returns not_started when there is no entry at all" do
    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.status).to eq("not_started")
    expect(r.work_minutes).to eq(0)
  end

  it "returns open when only clock_in exists" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.start_at).to be_present
    expect(r.end_at).to be_nil
    expect(r.work_minutes).to eq(0)
    expect(r.status).to eq("open")
  end

  it "returns closed and work minutes when both in/out exist" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,
                      happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out,
                      happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.work_minutes).to eq(9 * 60)
    expect(r.status).to eq("closed")
  end

  it "returns inconsistent_data when there is no clock_in but some entries exist" do
    TimeEntry.create!(user_id: 1, kind: :clock_out,
                      happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web")
    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.status).to eq("inconsistent_data")
    expect(r.work_minutes).to eq(0)
  end

  it "uses first clock_in and last clock_out if multiple exist" do
    TimeEntry.create!(user_id: 1, kind: :clock_in,  happened_at: Time.zone.parse("2025-08-21 08:55"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_in,  happened_at: Time.zone.parse("2025-08-21 09:10"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-21 17:50"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-21 18:05"), source: "web")

    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.start_at.iso8601).to include("08:55")
    expect(r.end_at.iso8601).to include("18:05")
  end

  it "deducts break minutes (no rounding)" do
    date = Date.parse("2025-08-21")
    TimeEntry.create!(user_id: 1, kind: :clock_in,  happened_at: Time.zone.parse("2025-08-21 09:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_start, happened_at: Time.zone.parse("2025-08-21 12:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_end,   happened_at: Time.zone.parse("2025-08-21 12:45"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-21 18:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.work_minutes).to  eq(540 - 45) # 09:00-18:00=480分から休憩45分を引く
    expect(r.break_minutes).to eq(45)
    expect(r.status).to eq("closed")
  end

  it "ignores unmatched break pairs and clips break within work range" do
    date = Date.parse("2025-08-22")
    # 勤務 10:00-19:00
    TimeEntry.create!(user_id: 1, kind: :clock_in,  happened_at: Time.zone.parse("2025-08-22 10:00"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :clock_out, happened_at: Time.zone.parse("2025-08-22 19:00"), source: "web")
    # 勤務外の休憩（前）→ クリップされて0
    TimeEntry.create!(user_id: 1, kind: :break_start, happened_at: Time.zone.parse("2025-08-22 09:30"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_end,   happened_at: Time.zone.parse("2025-08-22 09:50"), source: "web")
    # 休憩ペア1（勤務内）
    TimeEntry.create!(user_id: 1, kind: :break_start, happened_at: Time.zone.parse("2025-08-22 12:10"), source: "web")
    TimeEntry.create!(user_id: 1, kind: :break_end,   happened_at: Time.zone.parse("2025-08-22 12:40"), source: "web")
    # 片割れ（endのみ）→ 無視
    TimeEntry.create!(user_id: 1, kind: :break_end,   happened_at: Time.zone.parse("2025-08-22 15:00"), source: "web")

    r = described_class.summarize_day(user_id: 1, data: date)
    expect(r.break_minutes).to eq(30)           # 12:10-12:40 のみ有効
    expect(r.work_minutes).to eq(540 - 30)      # 10:00-19:00=540 から30分控除
  end
end
