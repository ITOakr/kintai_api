module Attendance
  class Calculator
    Result = Struct.new(:date, :start_at, :end_at, :work_minutes, :break_minutes, :status, keyword_init: true)  # 計算結果を格納する構造体

    def self.summarize_day(user_id:, date:)
      range = date.beginning_of_day..date.end_of_day
      base = TimeEntry.where(user_id: user_id, happened_at: range)

      # enum により scope が生える: clock_in, clock_out
      first_in_rec = base.clock_in.order(happened_at: :asc).first
      last_out_rec = base.clock_out.order(happened_at: :desc).first

      first_in = first_in_rec&.happened_at
      last_out = last_out_rec&.happened_at

      work_mins =
        if first_in && last_out
          ((last_out - first_in) / 60).to_i
        else
          0
        end

      break_mins = 0
      if first_in && last_out
        break_mins = sum_break_minutes_within(base, first_in..last_out)
        # 休憩時間が勤務時間を越えないように
        break_mins = [ break_mins, work_mins ].min
      end

      status = determine_status(first_in, last_out, base.exists?)

      Result.new(
        date: date,
        start_at: first_in,
        end_at: last_out,
        work_minutes: [ work_mins - break_mins, 0 ].max,  # 休憩時間を差し引いた実働時間（マイナスにならないように）
        break_minutes: break_mins,
        status: status
      )
    end

    def self.determine_status(first_in, last_out, has_entries)
      if first_in && last_out # 退勤済み
        "closed"
      elsif first_in # 出勤済み、未退勤
        "open"
      elsif has_entries # 出退勤いずれかが無い不整合データ
        "inconsistent_data"
      else # 全くデータが無い
        "not_started"
      end
    end

    def self.sum_break_minutes_within(scope, work_range)
      brks = scope.where(kind: [ :break_start, :break_end ]).order(:happened_at).pluck(:kind, :happened_at) # [ [kind, happened_at], ... ]

      stack = []
      total = 0

      brks.each do |kind, ts|
        if kind.to_s == "break_start"
          stack << ts
        elsif kind.to_s == "break_end"
          start_ts = stack.pop
          next unless start_ts

          s = [ start_ts, work_range.begin ].max
          e = [ ts, work_range.end ].min
          next if e <= s

          total += ((e - s) / 60).to_i
        end
      end

      total
    end
  end
end
