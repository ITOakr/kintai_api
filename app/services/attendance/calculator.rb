module Attendance
  class Calculator
    Result = Struct.new(:date, :start_at, :end_at, :work_minutes, :status, keyword_init: true)

    def self.summarize_day(user_id:, data:)
      range = data.beginning_of_day..data.end_of_day
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

        status = determine_status(first_in, last_out, base.exists?)

       Result.new(
        date: data,
        start_at: first_in,
        end_at: last_out,
        work_minutes: work_mins,
        status: status
      )
    end

    def self.determine_status(first_in, last_out, has_entries)
      if first_in && last_out
        "closed"
      elsif first_in
        "open"
      elsif has_entries
        "inconsistent_data"
      else
        "not_started"
      end
    end
  end
end
