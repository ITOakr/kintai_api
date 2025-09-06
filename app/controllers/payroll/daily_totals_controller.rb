module Payroll
  class DailyTotalsController < ApplicationController
    before_action :authenticate!
    # 管理者のみアクセス可能
    def show
      return render json: { error: "forbidden" }, status: :forbidden unless current_user.admin?

      date = Date.parse(params[:date].presence || Date.today.to_s)
      tz = ActiveSupport::TimeZone["Asia/Tokyo"]
      day_start = tz.parse("#{date} 00:00")
      day_end = tz.parse("#{date} 23:59:59") + 1.second
      range = day_start...(day_end - 1.second)

      user_ids = TimeEntry.where(happened_at: range).distinct.pluck(:user_id) # その日の勤怠記録があるユーザーID一覧を取得(重複なし)
      users = User.where(id: user_ids).select(:id, :name, :base_hourly_wage) # そのユーザーIDに対応するユーザー情報を取得

      users_by_id = users.index_by(&:id) # ユーザーIDをキーとしたハッシュに変換

      rows = []
      total = 0

      user_ids.each do |uid|
        user = users_by_id[uid]
        next unless user

        attendance_summary = Attendance::Calculator.summarize_day(user_id: uid, date: date)
        base = user.base_hourly_wage.to_i

        wage = ::Payroll::Calculator.daily_wage(
          base: base,
          work_minutes: attendance_summary.work_minutes,
          night_minutes: attendance_summary.night_minutes
        )

        rows << {
          user_id: uid,
          user_name: user.name,
          base_hourly_wage: base,
          work_minutes: attendance_summary.work_minutes,
          break_minutes: attendance_summary.break_minutes,
          night_minutes: attendance_summary.night_minutes,
          daily_wage: wage
        }
        total += wage
      end
      render json: {
        date: date.to_s,
        rows: rows.sort_by { |row| row[:user_id] },
        total_daily_wage: total
      }
    end
  end
end
