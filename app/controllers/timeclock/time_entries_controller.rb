module Timeclock
  class TimeEntriesController < ApplicationController
    before_action :authenticate!, only: [ :index, :create ]

    def create
      attrs = time_entry_params.to_h
      attrs[:user_id] ||= current_user&.id
      entry = TimeEntry.new(attrs)
      if entry.save
        render json: entry, status: :created
      else
        render json: { errors: entry.errors.full_messages }, status: :unprocessable_content
      end
    end

    def index
      user_id = params.require(:user_id)
      # もしログインしているユーザーが従業員でログインしているユーザーIDと取得しようとしているユーザーIDが違うなら403
      if current_user.employee? && current_user.id.to_s != user_id.to_s
        return render json: { error: "forbidden" }, status: :forbidden
      end
      date = Date.parse(params.require(:date))
      range = date.beginning_of_day..date.end_of_day
      entries = TimeEntry.where(user_id: user_id, happened_at: range).order(:happened_at)
      render json: entries
    end

    private

    def time_entry_params
      params.permit(:user_id, :kind, :happened_at, :source)
    end
  end
end
