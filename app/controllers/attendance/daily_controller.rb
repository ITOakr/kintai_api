# 指定されたユーザーの，ある1日の勤怠情報を表示
module Attendance
  class DailyController < ApplicationController
    before_action :authenticate!, only: [ :show, :me ]

    # GET /attendance/daily?user_id=1&date=YYYY-MM-DD ← 他人参照はadminのみ
    def show
      user_id = params.require(:user_id)
      if current_user.employee? && current_user.id.to_s != user_id.to_s
        return render json: { error: "forbidden" }, status: :forbidden
      end
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

    # GET /attendance/daily/me?date=YYYY-MM-DD ← 自分の勤怠を参照
    def me
      date = begin
        Date.parse(params[:date].presence || Date.today.to_s)
      rescue ArgumentError
        Date.current
      end

      r = Attendance::Calculator.summarize_day(user_id: current_user.id, date: date)
      render json: {
        date: r.date.to_s,
        actual: {
          start: r.start_at&.iso8601,
          end: r.end_at&.iso8601
        },
        totals: {
          work: r.work_minutes,
          break: r.break_minutes,
          overtime: 0,
          night: 0,
          holiday: 0
        },
        status: r.status
      }
    end
  end
end
