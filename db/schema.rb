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

ActiveRecord::Schema[7.1].define(version: 2022_02_28_010925) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "token", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.uuid "key", null: false
    t.bigint "category_id", null: false
    t.decimal "amount", precision: 11, scale: 2, null: false
    t.date "starts_at", null: false
    t.date "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "ends_at"], name: "index_budgets_on_category_id_and_ends_at", unique: true
    t.index ["category_id", "starts_at"], name: "index_budgets_on_category_id_and_starts_at", unique: true
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["key"], name: "index_budgets_on_key", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.uuid "key", null: false
    t.bigint "user_id", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_categories_on_key", unique: true
    t.index ["user_id", "description"], name: "index_categories_on_user_id_and_description", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.uuid "key", null: false
    t.bigint "user_id", null: false
    t.text "description", null: false
    t.decimal "amount", precision: 11, scale: 2, null: false
    t.date "starts_at", null: false
    t.date "ends_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_goals_on_key", unique: true
    t.index ["user_id", "description"], name: "index_goals_on_user_id_and_description", unique: true
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.uuid "key", null: false
    t.bigint "category_id"
    t.bigint "wallet_id", null: false
    t.date "effective_date", null: false
    t.decimal "amount", precision: 11, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_payments_on_category_id"
    t.index ["effective_date"], name: "index_payments_on_effective_date"
    t.index ["key"], name: "index_payments_on_key", unique: true
    t.index ["wallet_id"], name: "index_payments_on_wallet_id"
  end

  create_table "users", force: :cascade do |t|
    t.uuid "key", null: false
    t.text "full_name"
    t.text "nickname", null: false
    t.text "username"
    t.text "email", null: false
    t.text "password_digest", null: false
    t.text "documentation"
    t.date "born_on"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["documentation"], name: "index_users_on_documentation", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["key"], name: "index_users_on_key", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.uuid "key", null: false
    t.bigint "user_id", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "balance", precision: 11, scale: 2, null: false
    t.index ["key"], name: "index_wallets_on_key", unique: true
    t.index ["user_id", "description"], name: "index_wallets_on_user_id_and_description", unique: true
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "access_tokens", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "categories", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "payments", "categories"
  add_foreign_key "payments", "wallets"
  add_foreign_key "wallets", "users"
end
