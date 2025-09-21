class DailySummaryController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /daily_summary
  def show
    date_str = params.require(:date)
    date = Date.parse(date_str)
    summary = DailySummaryService.new(date).perform
    render json: summary
  rescue ArgumentError
    render json: { error: "Invalid date format", received: date_str }, status: :bad_request
  end
end
