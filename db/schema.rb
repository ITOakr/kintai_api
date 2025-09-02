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

ActiveRecord::Schema[8.0].define(version: 2025_09_02_070112) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["email"], name: "index_users_on_email"
  end

  add_foreign_key "time_entries", "users", validate: false
end
