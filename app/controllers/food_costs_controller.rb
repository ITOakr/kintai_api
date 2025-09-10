class FoodCostsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /v1/food_costs?date=YYYY-MM-DD
  def show
    date = parse_date!(params[:date])
    return if performed?
    food_cost = FoodCost.find_by(date: date)
    render json: food_cost ? serialize(food_cost) : { date: date.to_s, amount_yen: nil, note: nil }
  end

  # PUT /v1/food_costs?date=YYYY-MM-DD
  # body: amount_yen, note(optional)
  def upsert
    date = parse_date!(params[:date])
    return if performed?
    amount = params[:amount_yen].to_i
    note = params[:note].presence

    food_cost = FoodCost.find_or_initialize_by(date: date)
    food_cost.amount_yen = amount
    food_cost.note = note
    if food_cost.save
      render json: serialize(food_cost)
    else
      render json: { errors: food_cost.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def parse_date!(date_str)
    Date.parse(date_str.presence || Date.today.to_s)
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end

  def serialize(sale)
    {
      id: sale.id,
      date: sale.date.to_s,
      amount_yen: sale.amount_yen,
      note: sale.note
    }
  end
end
