module Attendance
  class DailyController < ApplicationController
    def show
      user_id = params.require(:user_id)
      date = Date.parse(params.require(:date))
      range = date.beginning_of_day..date.end_of_day

      base = TimeEntry.where(user_id:, happened_at: range)

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

      status = calculate_status(first_in, last_out, base.exists?)

      render json: {
        date: date.to_s,
        actual: {
          start: first_in&.iso8601,
          end: last_out&.iso8601
        },
        totals: {
          work: work_mins,
          break: 0,
          overtime: 0,
          night: 0,
          holiday: 0
        },
        status: status
      }
    end

    private

    def calculate_status(first_in, last_out, has_entries)
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
