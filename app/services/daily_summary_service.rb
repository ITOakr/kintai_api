class DailySummaryService
  def initialize(date)
    @date = date
    @tz = ActiveSupport::TimeZone["Asia/Tokyo"]
  end

  def perform
    sales_record = fetch_sales
    food_costs_total = fetch_food_costs_total
    wage_summary = calculate_wage_summary

    # 各比率を計算
    l_ratio = calculate_ratio(wage_summary[:total_daily_wage], sales_record&.amount_yen)
    f_ratio = calculate_ratio(food_costs_total, sales_record&.amount_yen)
    f_l_ratio = calculate_ratio(wage_summary[:total_daily_wage] + food_costs_total, sales_record&.amount_yen)

    {
      date: @date.to_s,
      sales: sales_record&.amount_yen,
      sales_note: sales_record&.note,
      total_wage: wage_summary[:total_daily_wage],
      wage_rows: wage_summary[:rows],
      food_costs_total: food_costs_total,
      l_ratio: l_ratio,
      f_ratio: f_ratio,
      f_l_ratio: f_l_ratio
    }
  end

  private

  def fetch_sales
    Sale.find_by(date: @date)
  end

  def fetch_food_costs_total
    FoodCost.where(date: @date).sum(:amount_yen)
  end

  def calculate_wage_summary
    day_start = @tz.parse("#{@date} 00:00")
    day_end = @tz.parse("#{@date} 23:59:59") + 1.second
    range = day_start...(day_end - 1.second)

    user_ids = TimeEntry.where(happened_at: range).distinct.pluck(:user_id)
    users = User.where(id: user_ids).select(:id, :name, :base_hourly_wage)
    users_by_id = users.index_by(&:id)

    rows = []
    total = 0
    user_ids.each do |uid|
      user = users_by_id[uid]
      next unless user

      summary = Attendance::Calculator.summarize_day(user_id: uid, date: @date)
      next if summary.work_minutes.to_i <= 0

      wage = ::Payroll::Calculator.daily_wage(
        base: user.base_hourly_wage.to_i,
        work_minutes: summary.work_minutes,
        night_minutes: summary.night_minutes
      )
      rows << {
        user_id: uid,
        user_name: user.name,
        base_hourly_wage: user.base_hourly_wage.to_i,
        work_minutes: summary.work_minutes,
        break_minutes: summary.break_minutes,
        night_minutes: summary.night_minutes,
        daily_wage: wage
      }
      total += wage
    end
    { rows: rows.sort_by { |row| row[:user_id] }, total_daily_wage: total }
  end

  def calculate_ratio(numerator, denominator)
    return nil if denominator.nil? || denominator.to_i <= 0
    (numerator.to_f / denominator.to_f).round(4)
  end
end
