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

ActiveRecord::Schema[7.0].define(version: 2023_07_02_152809) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "github_orgs", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "package_count"
  end

  create_table "measurements", force: :cascade do |t|
    t.bigint "package_id", null: false
    t.bigint "count"
    t.datetime "measured_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id"], name: "index_measurements_on_package_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.bigint "repository_id", null: false
    t.bigint "download_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_packages_on_repository_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name"
    t.bigint "github_org_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_org_id"], name: "index_repositories_on_github_org_id"
  end

  create_table "version_measurements", force: :cascade do |t|
    t.bigint "package_id", null: false
    t.bigint "version_id", null: false
    t.integer "count"
    t.datetime "measured_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id"], name: "index_version_measurements_on_package_id"
    t.index ["version_id"], name: "index_version_measurements_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.bigint "package_id", null: false
    t.string "version"
    t.integer "download_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id"], name: "index_versions_on_package_id"
  end

  add_foreign_key "measurements", "packages"
  add_foreign_key "packages", "repositories"
  add_foreign_key "repositories", "github_orgs"
  add_foreign_key "version_measurements", "packages"
  add_foreign_key "version_measurements", "versions"
  add_foreign_key "versions", "packages"
end
