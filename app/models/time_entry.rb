class TimeEntry < ApplicationRecord
  belongs_to :user, optional: true
  enum :kind, { clock_in: 0, clock_out: 1, break_start: 2, break_end: 3 }

  validates :user_id, presence: true
  validates :happened_at, presence: true
  validates :source, presence: true
  validates :kind, presence: true

  validate :sequence_rules

  def as_json(options = {})
    super(options).merge("kind" => kind)
  end

  private

  def day_range
    day = happened_at.in_time_zone.to_date
    day.beginning_of_day..day.end_of_day
  end

  def last_of_kind_before(kind_sym, time)
    TimeEntry.where(user_id: user_id, kind: kind_sym, happened_at: day_range)
             .where("happened_at < ?", time)
             .order(happened_at: :desc)
             .first
  end

  def exists_kind_between?(kind_sym, after_time, before_time)
    TimeEntry.where(user_id: user_id, kind: kind_sym, happened_at: day_range)
             .where("happened_at > ?", after_time)
             .where("happened_at < ?", before_time)
             .exists?
  end

  def sequence_rules
    return if user_id.blank? || happened_at.blank? || kind.blank?

    case kind.to_sym
    when :clock_in
      # 直近のclock_inが未クローズ（その後のclock_outが無い）ならNG
      last_in = last_of_kind_before(:clock_in, happened_at)
      if last_in && !exists_kind_between?(:clock_out, last_in.happened_at, happened_at)
        errors.add(:base, "clock_in already exists and not closed yet for the day")
      end

    when :clock_out
      # 対応するclock_inが必要。かつ、すでにクローズ済みでないこと
      last_in = last_of_kind_before(:clock_in, happened_at)
      if last_in.nil?
        errors.add(:base, "clock_out requires a prior clock_in")
      elsif exists_kind_between?(:clock_out, last_in.happened_at, happened_at)
        errors.add(:base, "already clocked out after the last clock_in")
      elsif happened_at <= last_in.happened_at
        errors.add(:happened_at, "must be after the last clock_in")
      end

    when :break_start
      # 勤務中（open shift）が前提。かつ既に休憩中でないこと
      last_in = last_of_kind_before(:clock_in, happened_at)
      open_shift = last_in && !exists_kind_between?(:clock_out, last_in.happened_at, happened_at)
      unless open_shift
        errors.add(:base, "break_start requires an open shift")
      end

      last_break_start = last_of_kind_before(:break_start, happened_at)
      if last_break_start && !exists_kind_between?(:break_end, last_break_start.happened_at, happened_at)
        errors.add(:base, "already on break (break_start exists without break_end)")
      end

    when :break_end
      # 直近のbreak_startが必要、かつ順序正しいこと
      last_break_start = last_of_kind_before(:break_start, happened_at)
      if last_break_start.nil?
        errors.add(:base, "break_end requires a prior break_start")
      elsif exists_kind_between?(:break_end, last_break_start.happened_at, happened_at)
        errors.add(:base, "break already ended after the last break_start")
      elsif happened_at <= last_break_start.happened_at
        errors.add(:happened_at, "must be after the last break_start")
      end
    end
  end
end
