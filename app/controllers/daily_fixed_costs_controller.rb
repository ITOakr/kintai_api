class DailyFixedCostsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # PUT /v1/daily_fixed_costs?date=YYYY-MM-DD
  def upsert
    date = Date.parse(params.require(:date))
    employee_count = params.require(:full_time_employee_count).to_i

    fixed_cost = DailyFixedCost.find_or_initialize_by(date: date)
    fixed_cost.full_time_employee_count = employee_count

    if fixed_cost.save
      render json: fixed_cost, status: :ok
    else
      render json: { errors: fixed_cost.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end
end
