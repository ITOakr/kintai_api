# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# IDが1のユーザーを探し、もし存在しなければ作成します。

# 存在する場合は、パスワードだけを更新します。

# これにより、このスクリプトは何度実行しても安全になります。

admin = User.find_or_initialize_by(id: 1)

# unless user
#   user = User.new(id: 1)
#   user.save(validate: false) # バリデーションをスキップして保存
# end

# 既にユーザーが存在した場合、パスワードが未設定なら設定する

admin.assign_attributes(
  name: "Admin User",
  email: "admin@example.com",
  password: "adminpass",
  role: :admin
)

admin.save(validate: false) # バリデーションをスキップして保存

puts "管理者ユーザーを作成または更新しました: #{admin.email} / パスワード: adminpass"

employee = User.find_or_initialize_by(id: 2)

employee.assign_attributes(
  name: "Employee User",
  email: "employee@example.com",
  password: "employeepass",
  role: :employee
)

employee.save(validate: false) # バリデーションをスキップして保存

puts "従業員ユーザーを作成または更新しました: #{employee.email} / パスワード: employeepass"
