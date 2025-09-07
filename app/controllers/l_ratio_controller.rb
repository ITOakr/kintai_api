class LRatioController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  def daily
    date = parse_date!(params[:date])
    return if performed?
    sales = Sale.find_by(date: date)&.amount_yen
    total_wage = compute_total_wage(date)

    lratio_val = if sales.nil? || sales.to_i <= 0
      nil
    else
      (total_wage.to_f / sales.to_f).round(4)
    end

    render json: {
      date: date.to_s,
      daily_sales: sales,
      total_daily_wage: total_wage,
      lratio: lratio_val
    }
  end

  private

  def parse_date!(date_str)
    Date.parse(date_str.presence || Date.today.to_s)
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end

  def compute_total_wage(date)
    tz = ActiveSupport::TimeZone["Asia/Tokyo"]
    day_start = tz.parse("#{date} 00:00")
    day_end = tz.parse("#{date} 23:59:59") + 1.second
    range = day_start...(day_end - 1.second)

    user_ids = TimeEntry.where(happened_at: range).distinct.pluck(:user_id)
    users = User.where(id: user_ids).select(:id, :base_hourly_wage)
    users_by_id = users.index_by(&:id)

    total = 0
    user_ids.each do |uid|
      user = users_by_id[uid]
      next unless user

      attendance_summary = Attendance::Calculator.summarize_day(user_id: uid, date: date)
      next if attendance_summary.work_minutes.to_i <= 0

      base = user.base_hourly_wage.to_i
      wage = ::Payroll::Calculator.daily_wage(
        base: base,
        work_minutes: attendance_summary.work_minutes,
        night_minutes: attendance_summary.night_minutes
      )
      total += wage
    end
    total
  end
end
