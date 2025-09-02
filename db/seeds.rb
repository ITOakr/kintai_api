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

user = User.find_or_create_by!(id: 1) do |u|
u.name = "Demo"
u.email = "demo@example.com"
u.password = "pass1234" # 新規作成時にパスワードを設定
end

# 既にユーザーが存在した場合、パスワードが未設定なら設定する

if user.password_digest.blank?
user.password = "pass1234"
user.save!
end

puts "Seed data for User ID:1 has been successfully created or updated."
