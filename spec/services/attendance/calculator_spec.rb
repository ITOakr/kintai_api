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
end
