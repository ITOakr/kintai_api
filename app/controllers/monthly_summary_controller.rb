class MonthlySummaryController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  def show
    year = params.require(:year).to_i
    month = params.require(:month).to_i

    summary = MonthlySummaryService.new(year, month).perform
    render json: summary
  rescue ArgumentError, Date::Error
    render json: { error: "Invalid_year_or_month" }, status: :bad_request
  end
end
