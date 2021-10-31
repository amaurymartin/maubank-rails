# frozen_string_literal: true

ActiveRecord::Schema.define(version: 2021_10_31_053007) do

  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.uuid "key", null: false
    t.text "full_name"
    t.text "nickname", null: false
    t.text "username"
    t.text "email", null: false
    t.text "password_digest", null: false
    t.text "documentation"
    t.date "date_of_birth"
    t.datetime "confirmed_at", precision: 6
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["documentation"], name: "index_users_on_documentation", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["key"], name: "index_users_on_key", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.uuid "key", null: false
    t.bigint "user_id", null: false
    t.text "description", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["key"], name: "index_wallets_on_key", unique: true
    t.index ["user_id", "description"], name: "index_wallets_on_user_id_and_description", unique: true
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "wallets", "users"
end
