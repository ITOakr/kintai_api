# 指定されたユーザーの，ある1日の勤怠情報を表示
module Attendance
  class DailyController < ApplicationController
    def show
      user_id = params.require(:user_id)
      date = Date.parse(params.require(:date))  # "YYYY-MM-DD"文字列をDateオブジェクトに変換

      attendance_summary = Attendance::Calculator.summarize_day(user_id: user_id, date: date) # 計算処理を呼び出し

      render json: {
        date: attendance_summary.date.to_s, # "YYYY-MM-DD"文字列をDateオブジェクトに変換
        actual: {
          start: attendance_summary.start_at&.iso8601,  # ISO 8601形式の文字列に変換（nil許容）
          end: attendance_summary.end_at&.iso8601
        },
        totals: {
          work: attendance_summary.work_minutes,
          break: attendance_summary.break_minutes,
          overtime: 0,
          night: 0,
          holiday: 0
        },
        status: attendance_summary.status
      }
    end
  end
end
