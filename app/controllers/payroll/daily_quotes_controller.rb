module Payroll
  class DailyQuotesController < ApplicationController
    before_action :authenticate!

    def me
      date = Date.parse(params[:date].presence || Date.today.to_s)
      render json: quote_for(user_id: current_user.id, date: date)
    end

    def user
      user_id = params.require(:user_id)
      return render json: { error: "forbidden" }, status: :forbidden if current_user.employee? && current_user.id.to_s != user_id.to_s

      date = Date.parse(params[:date].presence || Date.today.to_s)
      render json: quote_for(user_id: user_id, date: date)
    end

    private

    def quote_for(user_id:, date:)
      attendance_summary = Attendance::Calculator.summarize_day(user_id: user_id, date: date)
      base = User.find(user_id).base_hourly_wage.to_i

      wage = ::Payroll::Calculator.daily_wage(
        base: base,
        work_minutes: attendance_summary.work_minutes,
        night_minutes: attendance_summary.night_minutes
      )

      {
        date: date.to_s,
        user_id: user_id.to_i,
        base_hourly_wage: base,
        work_minutes: attendance_summary.work_minutes,
        break_minutes: attendance_summary.break_minutes,
        night_minutes: attendance_summary.night_minutes,
        daily_wage: wage,
        status: attendance_summary.status
      }
    end
  end
end
