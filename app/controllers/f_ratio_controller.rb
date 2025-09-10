class FRatioController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /v1/f_ratio/daily
  def daily
    date = parse_date!(params[:date])
    return if performed?
    sales = Sale.find_by(date: date)&.amount_yen
    food_cost = FoodCost.find_by(date: date)&.amount_yen

    f_ratio_val = calculate_f_ratio(food_cost, sales)

    render json: {
      date: date.to_s,
      daily_sales: sales,
      daily_food_cost: food_cost,
      f_ratio: f_ratio_val
    }
  end

  def monthly
    year = (params[:year].presence || Date.today.year).to_i
    month = (params[:month].presence || Date.today.month).to_i
    begin
      first = Date.new(year, month, 1)
    rescue ArgumentError
      render json: { error: "invalid_year_or_month" }, status: :bad_request
    end
    last = first.end_of_month

    days = []
    month_sales_sum = 0
    month_food_cost_sum = 0

    (first..last).each do |date|
      sales = Sale.find_by(date: date)&.amount_yen
      food_cost = FoodCost.find_by(date: date)&.amount_yen
      month_sales_sum += sales.to_i if sales
      month_food_cost_sum += food_cost.to_i if food_cost

      f_ratio_val = calculate_f_ratio(food_cost, sales)

      days << {
        date: date.to_s,
        daily_sales: sales,
        daily_food_cost: food_cost,
        f_ratio: f_ratio_val
      }
    end

    month_f_ratio = if month_sales_sum <= 0
      nil
    else
      (month_food_cost_sum.to_f / month_sales_sum.to_f).round(4)
    end

    render json: {
      year: year,
      month: month,
      days: days,
      monthly_sales: month_sales_sum,
      monthly_food_cost: month_food_cost_sum,
      monthly_f_ratio: month_f_ratio
    }
  end

  private

  def calculate_f_ratio(food_cost, sales)
    return nil if sales.nil? || sales.to_i <= 0
    (food_cost.to_f / sales.to_f).round(4)
  end

  def parse_date!(date_str)
    Date.parse(date_str.presence || Date.today.to_s)
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end
end
