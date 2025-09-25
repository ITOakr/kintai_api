class FoodCostsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /v1/food_costs?date=YYYY-MM-DD
  def show
    date = parse_date!(params[:date])
    return if performed?
    food_cost = FoodCost.where(date: date)
    render json: food_cost.map { |fc| serialize(fc) }
  end

  # PUT /v1/food_costs?date=YYYY-MM-DD
  # body: amount_yen, note(optional)
  def upsert
    date = parse_date!(params[:date])
    return if performed?
    service = UpsertFoodCostsService.new(date, food_cost_params, current_user)

    if service.perform
      new_food_costs = FoodCost.where(date: date)
      render json: new_food_costs.map { |fc| serialize(fc) }, status: :ok
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  private

  def parse_date!(date_str)
    Date.parse(date_str.presence || Date.today.to_s)
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end

  def serialize(fc)
    {
      id: fc.id,
      date: fc.date.to_s,
      category: fc.category,
      amount_yen: fc.amount_yen,
      note: fc.note
    }
  end

  def food_cost_params
    (params[:food_costs] || []).map do |item|
      item.permit(:category, :amount_yen, :note)
    end
  end
end
