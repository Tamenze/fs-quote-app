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

ActiveRecord::Schema[8.0].define(version: 2025_10_13_180315) do
  create_table "quotes", force: :cascade do |t|
    t.text "body", null: false
    t.string "attribution", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_quotes_on_created_at"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "quotes_tags", id: false, force: :cascade do |t|
    t.integer "quote_id", null: false
    t.integer "tag_id", null: false
    t.index ["quote_id", "tag_id"], name: "idx_quotes_tags_on_quote_and_tag", unique: true
    t.index ["tag_id", "quote_id"], name: "idx_quotes_tags_on_tag_and_quote"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(name)", name: "index_tags_on_lower_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "quotes", "users", on_delete: :nullify
  add_foreign_key "quotes_tags", "quotes", on_delete: :cascade
  add_foreign_key "quotes_tags", "tags", on_delete: :cascade
  add_foreign_key "tags", "users", column: "created_by_id", on_delete: :nullify
end
