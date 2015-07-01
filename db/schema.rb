# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150701160133) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "auth_roles", force: :cascade do |t|
    t.string   "text_id"
    t.string   "name"
    t.string   "description"
    t.jsonb    "permissions"
    t.jsonb    "contexts"
    t.boolean  "is_deprecated"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "auth_roles", ["contexts"], name: "index_auth_roles_on_contexts", using: :gin
  add_index "auth_roles", ["permissions"], name: "index_auth_roles_on_permissions", using: :gin

  create_table "authentication_services", force: :cascade do |t|
    t.string   "uuid"
    t.string   "base_uri"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "uuid"
    t.integer  "creator_id"
    t.string   "etag"
    t.boolean  "is_deleted"
    t.datetime "deleted_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "storage_folders", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "name"
    t.text     "description"
    t.string   "storage_service_uuid"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "user_authentication_services", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "authentication_service_id"
    t.string   "uid"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "uuid"
    t.string   "etag"
    t.string   "email"
    t.string   "name"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.jsonb    "auth_role_ids"
  end

  add_index "users", ["auth_role_ids"], name: "index_users_on_auth_role_ids", using: :gin

end
