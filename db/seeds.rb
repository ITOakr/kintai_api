# db/seeds.rb

puts "Seeding database..."

# 管理者ユーザーを作成または更新
admin = User.find_or_initialize_by(email: "admin@example.com")
admin.assign_attributes(
  name: "管理者ユーザー",
  password: "adminpass",
  role: :admin,
  base_hourly_wage: 1500, # 管理者の時給
  status: :active
)
admin.save!
puts "Admin user: #{admin.email}"

# 従業員ユーザーを3人作成または更新
employees = []
3.times do |i|
  employee = User.find_or_initialize_by(email: "employee#{i + 1}@example.com")
  employee.assign_attributes(
    name: "従業員#{i + 1}",
    password: "employeepass",
    role: :employee,
    base_hourly_wage: 1004 # 時給を1004円に設定
  )
  employee.save!
  employees << employee
  puts "Employee user: #{employee.email}"
end

# 各従業員の打刻データを作成
dates_to_seed = [
  Date.parse("2025-09-06"),
  Date.parse("2025-09-07"),
  Date.parse("2025-09-08")
]

tz = ActiveSupport::TimeZone["Asia/Tokyo"]

employees.each do |emp|
  dates_to_seed.each do |date|
    # その従業員・その日付の既存データを一度削除
    TimeEntry.where(user_id: emp.id, happened_at: date.all_day).destroy_all

    # 17:30 に出勤
    TimeEntry.create!(user_id: emp.id, kind: :clock_in, happened_at: tz.parse("#{date} 17:30"), source: "seed")
    # 20:00-20:30 に休憩 (30分)
    TimeEntry.create!(user_id: emp.id, kind: :break_start, happened_at: tz.parse("#{date} 20:00"), source: "seed")
    TimeEntry.create!(user_id: emp.id, kind: :break_end, happened_at: tz.parse("#{date} 20:30"), source: "seed")
    # 23:00 に退勤 (実働5時間)
    TimeEntry.create!(user_id: emp.id, kind: :clock_out, happened_at: tz.parse("#{date} 23:00"), source: "seed")
  end
  puts "Generated time entries for #{emp.name} on #{dates_to_seed.join(', ')}"
end

puts "Seed completed!"
