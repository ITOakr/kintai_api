class DailyReportsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!


  def show
    date = Date.parse(params.require(:date))
    report = DailyReport.find_by(date: date)

    if report
      render json: report
    else
      render json: { date: date.to_s, content: "" }
    end
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end

  def upsert
    date = Date.parse(params.require(:date))
    content = params[:content]

    report = DailyReport.find_or_initialize_by(date: date)
    report.content = content

    if report.save
      render json: report, status: :ok
    else
      render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end
end
