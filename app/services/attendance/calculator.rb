module Attendance
  class Calculator
    Result = Struct.new(:date, :start_at, :end_at, :work_minutes, :break_minutes, :night_minutes, :status, keyword_init: true)  # 計算結果を格納する構造体
    AttendanceDetails = Struct.new(:work_segments, :break_minutes, keyword_init: true) # 勤務セグメントと休憩時間を格納する構造体

    def self.summarize_day(user_id:, date:)
      range = date.beginning_of_day..date.end_of_day
      base = TimeEntry.where(user_id: user_id, happened_at: range)

      # enum により scope が生える: clock_in, clock_out
      first_in_rec = base.clock_in.order(happened_at: :asc).first
      last_out_rec = base.clock_out.order(happened_at: :desc).first

      first_in = first_in_rec&.happened_at
      last_out = last_out_rec&.happened_at

      last_punch = base.order(:happened_at).last
      status = determine_status(last_punch)

      details = calculate_attendance_details(user_id: user_id, date: date)
      # 勤務時間の計算
      work_mins = calculate_work_minutes(work_segments: details.work_segments)
      # 休憩時間
      break_mins = details.break_minutes
      # 夜勤時間の計算
      night_mins = calculate_night_minutes(work_segments: details.work_segments, date: date)

      Result.new(
        date: date,
        start_at: first_in,
        end_at: last_out,
        work_minutes: work_mins,  # 休憩時間を差し引いた実働時間（マイナスにならないように）
        break_minutes: break_mins,
        night_minutes: night_mins,
        status: status
      )
    end

    def self.summarize_day_from_entries(entries)
      return Result.new(status: "not_started") if entries.empty?

      # enum により scope が生える: clock_in, clock_out
      first_in_rec = entries.select(&:clock_in?).min_by(&:happened_at)
      last_out_rec = entries.select(&:clock_out?).max_by(&:happened_at)

      first_in = first_in_rec&.happened_at
      last_out = last_out_rec&.happened_at

      last_punch = entries.max_by(&:happened_at)
      status = determine_status(last_punch)

      date = entries.first.happened_at.to_date

      details = calculate_attendance_details_from_entries(entries)
      # 勤務時間の計算
      work_mins = calculate_work_minutes(work_segments: details.work_segments)
      # 休憩時間
      break_mins = details.break_minutes
      # 夜勤時間の計算
      night_mins = calculate_night_minutes(work_segments: details.work_segments, date: date)

      Result.new(
        date: date,
        start_at: first_in,
        end_at: last_out,
        work_minutes: work_mins,  # 休憩時間を差し引いた実働時間（マイナスにならないように）
        break_minutes: break_mins,
        night_minutes: night_mins,
        status: status
      )
    end

    def self.calculate_work_minutes(work_segments:)
      total_seconds = work_segments.sum { |seg| seg.end - seg.begin }
      (total_seconds / 60).to_i
    end

    def self.determine_status(last_punch)
      if last_punch.nil? # 打刻が一つも無い
        return "not_started"
      end
      case last_punch.kind.to_s
      when "clock_out"
        "closed"
      when "break_start"
        "on_break"
      when "break_end", "clock_in"
        "open"
      end
    end

    def self.calculate_night_minutes(work_segments:, date:)
      tz = ActiveSupport::TimeZone["Asia/Tokyo"]

      day_start = tz.parse("#{date} 00:00")
      day_05 = tz.parse("#{date} 05:00")
      day_22 = tz.parse("#{date} 22:00")
      day_24 = tz.parse("#{date} 23:59:59") + 1.second

      night_windows = [
        (day_start...day_05),
        (day_22...day_24)
      ]

      total_night_seconds = 0

      work_segments.each do |work_seg|
        night_windows.each do |night_win|
          s = [ work_seg.begin, night_win.begin ].max
          e = [ work_seg.end, night_win.end ].min
          next if e <= s

          total_night_seconds += e - s
        end
      end
      (total_night_seconds / 60).to_i
    end

    private

    def self.calculate_attendance_details(user_id:, date:)
      range = date.beginning_of_day..date.end_of_day
      entries = TimeEntry.where(user_id: user_id, happened_at: range).order(:happened_at)

      work_segments = []
      total_break_seconds = 0
      state = :off
      cur_start = nil
      break_start = nil

      entries.each do |e|
        case e.kind.to_s
        when "clock_in"
          if state == :off
            state = :on
            cur_start = e.happened_at
          end
        when "break_start"
          if state == :on
            work_segments << (cur_start...e.happened_at) if cur_start && e.happened_at > cur_start
            state = :break
            break_start = e.happened_at
          end
        when "break_end"
          if state == :break
            state = :on
            cur_start = e.happened_at
            total_break_seconds += (e.happened_at - break_start) if break_start && e.happened_at > break_start
          end
        when "clock_out"
          if state == :on
            work_segments << (cur_start...e.happened_at) if cur_start && e.happened_at > cur_start
            state = :off
            cur_start = nil
            break_start = nil
          elsif state == :break
            # 休憩中に退勤した場合、休憩時間は加算しない
            state = :off
            cur_start = nil
            break_start = nil
          end
        end
      end

      AttendanceDetails.new(
        work_segments: work_segments,
        break_minutes: (total_break_seconds / 60).to_i
      )
    end

    def self.calculate_attendance_details_from_entries(entries)
      work_segments = []
      total_break_seconds = 0
      state = :off
      cur_start = nil
      break_start = nil

      entries.each do |e|
        case e.kind.to_s
        when "clock_in"
          if state == :off
            state = :on
            cur_start = e.happened_at
          end
        when "break_start"
          if state == :on
            work_segments << (cur_start...e.happened_at) if cur_start && e.happened_at > cur_start
            state = :break
            break_start = e.happened_at
          end
        when "break_end"
          if state == :break
            state = :on
            cur_start = e.happened_at
            total_break_seconds += (e.happened_at - break_start) if break_start && e.happened_at > break_start
          end
        when "clock_out"
          if state == :on
            work_segments << (cur_start...e.happened_at) if cur_start && e.happened_at > cur_start
            state = :off
            cur_start = nil
            break_start = nil
          elsif state == :break
            # 休憩中に退勤した場合、休憩時間は加算しない
            state = :off
            cur_start = nil
            break_start = nil
          end
        end
      end

      AttendanceDetails.new(
        work_segments: work_segments,
        break_minutes: (total_break_seconds / 60).to_i
      )
    end
  end
end
