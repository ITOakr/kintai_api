class MonthlySummaryService
  def initialize(year, month)
    @year = year
    @month = month
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
  end

  def perform
    # 月全体の売上と食材費をまとめて取得
    sales_by_date = Sale.where(date: @start_date..@end_date).index_by(&:date)
    food_costs_by_date = FoodCost.where(date: @start_date..@end_date).group(:date).sum(:amount_yen)

    # 1日から最終日まで，1日ずつループ処理
    dates = (@start_date..@end_date).to_a
    # 日次サマリをバッチで取得
    daily_summaries = DailySummaryService.respond_to?(:batch_perform) ? DailySummaryService.batch_perform(dates) : dates.index_with { |date| DailySummaryService.new(date).perform }

    cumulative_sales = 0
    cumulative_food_costs = 0
    cumulative_wage = 0

    days_data = dates.map do |date|
      daily_summary = daily_summaries[date]
      sale_amount = sales_by_date[date]&.amount_yen
      food_cost_amount = food_costs_by_date[date] || 0
      total_wage = daily_summary[:total_wage]

      # 各比率を計算
      l_ratio = calculate_ratio(total_wage, sale_amount)
      f_ratio = calculate_ratio(food_cost_amount, sale_amount)
      f_l_ratio = calculate_ratio(total_wage + food_cost_amount, sale_amount)

      # 累積計算は未来日を除外
      if date > Date.current
        cumulative_f_l_ratio = nil
      else
        cumulative_sales += (sale_amount || 0)
        cumulative_food_costs += (food_cost_amount || 0)
        cumulative_wage += (total_wage || 0)
        cumulative_f_l_ratio = calculate_ratio(cumulative_wage + cumulative_food_costs, cumulative_sales)
      end
      if date > Date.current
        # 未来の日付のデータは空にする
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
          daily_food_costs: food_cost_amount,
          l_ratio: l_ratio,
          f_ratio: f_ratio,
          f_l_ratio: f_l_ratio,
          cumulative_f_l_ratio: cumulative_f_l_ratio
        }
      end
    end

    # 日々のデータを元に，月全体の合計値と比率を計算
    monthly_sales = days_data.sum { |d| d[:daily_sales].to_i }
    monthly_wage = days_data.sum { |d| d[:total_daily_wage].to_i }
    monthly_food_costs = days_data.sum { |d| d[:daily_food_costs].to_i }

    monthly_l_ratio = calculate_ratio(monthly_wage, monthly_sales)
    monthly_f_ratio = calculate_ratio(monthly_food_costs, monthly_sales)
    monthly_f_l_ratio = calculate_ratio(monthly_wage + monthly_food_costs, monthly_sales)

    # 最終的な結果を返す
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
end
