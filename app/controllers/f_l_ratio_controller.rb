class FLRatioController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /v1/f_l_ratio/daily
  def daily
    date = parse_date!(params[:date])
    return if performed?
    sale = Sale.find_by(date: date)&.amount_yen
    food_cost = FoodCost.find_by(date: date)&.amount_yen
    total_wage = compute_total_wage(date)

    f_l_ratio_val = if sale.nil? || sale.to_i <= 0 || food_cost.nil? || food_cost.to_i <= 0
      nil
    else
      ((total_wage.to_f + food_cost.to_f) / sale.to_f).round(4)
    end

    render json: {
      date: date.to_s,
      daily_sale: sale,
      total_daily_wage: total_wage,
      f_l_ratio: f_l_ratio_val
    }
  end

  def monthly
    year = (params[:year].presence || Date.today.year).to_i
    month = (params[:month].presence || Date.today.month).to_i
    begin
      first = Date.new(year, month, 1)
    rescue ArgumentError
      render json: { error: "invalid_year_or_month" }, status: :bad_request
      return
    end
    last = first.end_of_month

    days = []
    month_sale_sum = 0
    month_food_cost_sum = 0
    month_wage_sum = 0

    (first..last).each do |date|
      sale = Sale.find_by(date: date)&.amount_yen
      food_cost = FoodCost.find_by(date: date)&.amount_yen
      wage = compute_total_wage(date)
      month_sale_sum += sale.to_i if sale
      month_food_cost_sum += food_cost.to_i if food_cost
      month_wage_sum += wage.to_i

      f_l_ratio_val = if sale.nil? || sale.to_i <= 0 || food_cost.nil? || food_cost.to_i <= 0
        nil
      else
        ((wage.to_f + food_cost.to_f) / sale.to_f).round(4)
      end

      days << {
        date: date.to_s,
        daily_sale: sale,
        total_daily_wage: wage,
        daily_food_cost: food_cost,
        f_l_ratio: f_l_ratio_val
      }
    end

    month_f_l_ratio = if month_sale_sum.to_i <= 0 || month_food_cost_sum.to_i <= 0
      nil
    else
      ((month_wage_sum.to_f + month_food_cost_sum.to_f) / month_sale_sum.to_f).round(4)
    end

    render json: {
      year: year,
      month: month,
      days: days,
      monthly_sale: month_sale_sum,
      monthly_wage: month_wage_sum,
      monthly_food_cost: month_food_cost_sum,
      monthly_f_l_ratio: month_f_l_ratio
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
