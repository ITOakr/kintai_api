# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_05_082948) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_logs", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.bigint "target_user_id"
    t.string "action"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_logs_on_admin_user_id"
    t.index ["target_user_id"], name: "index_admin_logs_on_target_user_id"
  end

  create_table "daily_fixed_costs", force: :cascade do |t|
    t.date "date", null: false
    t.integer "full_time_employee_count", default: 0, null: false
    t.integer "daily_wage_per_employee", default: 10800, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_fixed_costs_on_date", unique: true
  end

  create_table "daily_reports", force: :cascade do |t|
    t.date "date", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_reports_on_date", unique: true
  end

  create_table "food_costs", force: :cascade do |t|
    t.date "date", null: false
    t.integer "category", null: false
    t.integer "amount_yen", default: 0, null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_food_costs_on_date"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "message"
    t.boolean "read", default: false, null: false
    t.string "notification_type"
    t.string "link_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sales", force: :cascade do |t|
    t.date "date", null: false
    t.integer "amount_yen", default: 0, null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_sales_on_date", unique: true
    t.check_constraint "amount_yen >= 0", name: "chk_amount_nonneg"
  end

  create_table "time_entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "kind", null: false
    t.datetime "happened_at", null: false
    t.string "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["happened_at"], name: "index_time_entries_on_happened_at"
    t.index ["user_id", "happened_at"], name: "index_time_entries_on_user_id_and_happened_at"
    t.index ["user_id"], name: "index_time_entries_on_user_id"
    t.check_constraint "kind = ANY (ARRAY[0, 1, 2, 3])", name: "chk_time_entries_kind_enum"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.integer "role", default: 0, null: false
    t.integer "base_hourly_wage", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["role"], name: "index_users_on_role"
    t.check_constraint "base_hourly_wage >= 0", name: "base_hourly_wage_non_negative"
  end

  create_table "wage_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "wage", null: false
    t.date "effective_from", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wage_histories_on_user_id"
  end

  add_foreign_key "admin_logs", "users", column: "admin_user_id"
  add_foreign_key "admin_logs", "users", column: "target_user_id"
  add_foreign_key "time_entries", "users"
  add_foreign_key "wage_histories", "users"
end
