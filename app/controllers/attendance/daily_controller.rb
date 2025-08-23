module Attendance
  class DailyController < ApplicationController
    def show
      user_id = params.require(:user_id)
      date = Date.parse(params.require(:date))

      attendance_summary = Attendance::Calculator.summarize_day(user_id: user_id, data: date)

      render json: {
        date: attendance_summary.date.to_s,
        actual: {
          start: attendance_summary.start_at&.iso8601,
          end: attendance_summary.end_at&.iso8601
        },
        totals: {
          work: attendance_summary.work_minutes,
          break: 0,
          overtime: 0,
          night: 0,
          holiday: 0
        },
        status: attendance_summary.status
      }
    end
  end
end
