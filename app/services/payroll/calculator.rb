module Payroll
  class Calculator
    # 日給計算
    # base: 時給（整数、円）
    # work_minutes: 実勤務時間（休憩控除）
    # night_minutes: 深夜該当分
    # 戻り値: 日給（整数、円，1円未満切り捨て）
    def self.daily_wage(base:, work_minutes:, night_minutes:)
      normal = base * (work_minutes.to_f / 60.0)
      night_bonus = (base * 0.25) * (night_minutes.to_f / 60.0)
      (normal + night_bonus).floor
    end
  end
end
