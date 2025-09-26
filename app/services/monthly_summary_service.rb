class MonthlySummaryService
  def initialize(year, month)
    @year = year
    @month = month
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
    @date_range = @start_date..@end_date
  end

  def perform
    # 月全体の売上と食材費をまとめて取得
    sales_by_date = Sale.where(date: @date_range).index_by(&:date)
    food_costs_by_date = FoodCost.where(date: @date_range).group(:date).sum(:amount_yen)
    fixed_costs_by_date = DailyFixedCost.where(date: @date_range).index_by(&:date)
    time_entries_by_date = TimeEntry.where(happened_at: @start_date.beginning_of_day..@end_date.end_of_day)
                                    .order(:happened_at)
                                    .group_by { |te| te.happened_at.to_date }

    user_ids = time_entries_by_date.values.flatten.map(&:user_id).uniq
    users_by_id = User.where(id: user_ids).index_by(&:id)

    wage_histories = WageHistory.where(user_id: user_ids)
                                .where("effective_from <= ?", @end_date)
                                .order(:user_id, effective_from: :desc)

    wages_by_user_id = wage_histories.group_by(&:user_id)
                                     .transform_values { |histories| histories.first&.wage }

    cumulative_sales = 0
    cumulative_food_costs = 0
    cumulative_wage = 0

    days_data = (@start_date..@end_date).map do |date|
      sale = sales_by_date[date]
      food_cost_total = food_costs_by_date[date] || 0
      fixed_cost = fixed_costs_by_date[date]
      sale_amount = sale&.amount_yen

      part_time_wage_summary = calculate_part_time_wage_for_day(
        date,
        time_entries_by_date[date] || [], # その日の勤怠データだけを渡す
        users_by_id,
        wages_by_user_id
      )

      fixed_wage = (fixed_cost&.full_time_employee_count || 0) * (fixed_cost&.daily_wage_per_employee || 10800)
      total_wage = part_time_wage_summary[:total_daily_wage] + fixed_wage

      l_ratio = calculate_ratio(total_wage, sale_amount)
      f_ratio = calculate_ratio(food_cost_total, sale_amount)
      f_l_ratio = calculate_ratio(total_wage + food_cost_total, sale_amount)

      cumulative_f_l_ratio = if date > Date.current
        nil
      else
        cumulative_sales += (sale_amount || 0)
        cumulative_food_costs += (food_cost_total || 0)
        cumulative_wage += (total_wage || 0)
        calculate_ratio(cumulative_wage + cumulative_food_costs, cumulative_sales)
      end

      if date > Date.current
        {
          date: date.to_s,
          daily_sales: nil,
          total_daily_wage: nil,
          daily_food_costs: nil,
          l_ratio: nil,
          f_ratio: nil,
          f_l_ratio: nil,
          cumulative_f_l_ratio: nil
        }
      else
        {
          date: date.to_s,
          daily_sales: sale_amount,
          total_daily_wage: total_wage,
          daily_food_costs: food_cost_total,
          l_ratio: l_ratio,
          f_ratio: f_ratio,
          f_l_ratio: f_l_ratio,
          cumulative_f_l_ratio: cumulative_f_l_ratio
        }
      end
    end

    monthly_sales = days_data.sum { |d| d[:daily_sales].to_i }
    monthly_wage = days_data.sum { |d| d[:total_daily_wage].to_i }
    monthly_food_costs = days_data.sum { |d| d[:daily_food_costs].to_i }
    monthly_l_ratio = calculate_ratio(monthly_wage, monthly_sales)
    monthly_f_ratio = calculate_ratio(monthly_food_costs, monthly_sales)
    monthly_f_l_ratio = calculate_ratio(monthly_wage + monthly_food_costs, monthly_sales)

    {
      year: @year,
      month: @month,
      days: days_data,
      monthly_sales: monthly_sales,
      monthly_wage: monthly_wage,
      monthly_food_costs: monthly_food_costs,
      monthly_l_ratio: monthly_l_ratio,
      monthly_f_ratio: monthly_f_ratio,
      monthly_f_l_ratio: monthly_f_l_ratio
    }
  end

  private

  def calculate_ratio(numerator, denominator)
    return nil if denominator.nil? || denominator.to_i <= 0
    (numerator.to_f / denominator.to_f).round(4)
  end

  def calculate_part_time_wage_for_day(date, time_entries, users_by_id, wages_by_user_id)
    entries_by_user_id = time_entries.group_by(&:user_id)
    total_wage = entries_by_user_id.sum do |user_id, entries|
      user = users_by_id[user_id]
      next 0 unless user

      summary = Attendance::Calculator.summarize_day(user_id: user_id, date: date)
      next 0 if summary.work_minutes.to_i.zero?

      wage_for_the_day = wages_by_user_id[user_id] || user.base_hourly_wage
      ::Payroll::Calculator.daily_wage(
        base: wage_for_the_day,
        work_minutes: summary.work_minutes,
        night_minutes: summary.night_minutes
      )
    end
    { total_daily_wage: total_wage }
  end
end
