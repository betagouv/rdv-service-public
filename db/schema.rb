# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_05_05_101547) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

  create_table "absences", force: :cascade do |t|
    t.bigint "agent_id"
    t.string "title"
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "recurrence"
    t.date "first_day", null: false
    t.time "start_time", null: false
    t.date "end_day", null: false
    t.time "end_time", null: false
    t.index ["agent_id"], name: "index_absences_on_agent_id"
    t.index ["organisation_id"], name: "index_absences_on_organisation_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "role", default: 0
    t.string "first_name"
    t.string "last_name"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.datetime "deleted_at"
    t.bigint "service_id"
    t.index ["confirmation_token"], name: "index_agents_on_confirmation_token", unique: true
    t.index ["email"], name: "index_agents_on_email", unique: true
    t.index ["invitation_token"], name: "index_agents_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_agents_on_invitations_count"
    t.index ["invited_by_id"], name: "index_agents_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_agents_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_agents_on_reset_password_token", unique: true
    t.index ["service_id"], name: "index_agents_on_service_id"
  end

  create_table "agents_organisations", id: false, force: :cascade do |t|
    t.bigint "agent_id"
    t.bigint "organisation_id"
    t.index ["agent_id"], name: "index_agents_organisations_on_agent_id"
    t.index ["organisation_id", "agent_id"], name: "index_agents_organisations_on_organisation_id_and_agent_id", unique: true
    t.index ["organisation_id"], name: "index_agents_organisations_on_organisation_id"
  end

  create_table "agents_rdvs", force: :cascade do |t|
    t.bigint "agent_id"
    t.bigint "rdv_id"
    t.index ["agent_id"], name: "index_agents_rdvs_on_agent_id"
    t.index ["rdv_id"], name: "index_agents_rdvs_on_rdv_id"
  end

  create_table "agents_users", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "agent_id"
    t.index ["agent_id"], name: "index_agents_users_on_agent_id"
    t.index ["user_id"], name: "index_agents_users_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cron"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "file_attentes", force: :cascade do |t|
    t.bigint "rdv_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "notifications_sent", default: 0
    t.datetime "last_creneau_sent_at"
    t.index ["rdv_id"], name: "index_file_attentes_on_rdv_id"
    t.index ["user_id"], name: "index_file_attentes_on_user_id"
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "lieux", force: :cascade do |t|
    t.string "name"
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.float "latitude"
    t.float "longitude"
    t.index ["organisation_id"], name: "index_lieux_on_organisation_id"
  end

  create_table "motif_libelles", force: :cascade do |t|
    t.string "name"
    t.bigint "service_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["service_id"], name: "index_motif_libelles_on_service_id"
  end

  create_table "motifs", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "default_duration_in_min", default: 30, null: false
    t.bigint "organisation_id"
    t.boolean "online", default: false, null: false
    t.integer "min_booking_delay", default: 1800
    t.integer "max_booking_delay", default: 7889238
    t.datetime "deleted_at"
    t.bigint "service_id"
    t.boolean "disable_notifications_for_users", default: false
    t.text "restriction_for_rdv"
    t.text "instruction_for_rdv"
    t.boolean "for_secretariat", default: false
    t.integer "location_type", default: 0, null: false
    t.index ["deleted_at"], name: "index_motifs_on_deleted_at"
    t.index ["organisation_id"], name: "index_motifs_on_organisation_id"
    t.index ["service_id"], name: "index_motifs_on_service_id"
  end

  create_table "motifs_plage_ouvertures", id: false, force: :cascade do |t|
    t.bigint "motif_id"
    t.bigint "plage_ouverture_id"
    t.index ["motif_id"], name: "index_motifs_plage_ouvertures_on_motif_id"
    t.index ["plage_ouverture_id"], name: "index_motifs_plage_ouvertures_on_plage_ouverture_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "departement"
    t.text "horaires"
    t.string "phone_number"
  end

  create_table "organisations_users", id: false, force: :cascade do |t|
    t.bigint "organisation_id"
    t.bigint "user_id"
    t.index ["organisation_id", "user_id"], name: "index_organisations_users_on_organisation_id_and_user_id", unique: true
    t.index ["organisation_id"], name: "index_organisations_users_on_organisation_id"
    t.index ["user_id"], name: "index_organisations_users_on_user_id"
  end

  create_table "plage_ouvertures", force: :cascade do |t|
    t.bigint "agent_id"
    t.string "title"
    t.bigint "organisation_id"
    t.date "first_day", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "recurrence"
    t.bigint "lieu_id"
    t.index ["agent_id"], name: "index_plage_ouvertures_on_agent_id"
    t.index ["lieu_id"], name: "index_plage_ouvertures_on_lieu_id"
    t.index ["organisation_id"], name: "index_plage_ouvertures_on_organisation_id"
  end

  create_table "rdvs", force: :cascade do |t|
    t.integer "duration_in_min", null: false
    t.datetime "starts_at", null: false
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "cancelled_at"
    t.bigint "motif_id"
    t.integer "sequence", default: 0, null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.integer "status", default: 0
    t.string "location"
    t.integer "created_by", default: 0
    t.text "notes"
    t.index ["created_by"], name: "index_rdvs_on_created_by"
    t.index ["motif_id"], name: "index_rdvs_on_motif_id"
    t.index ["organisation_id"], name: "index_rdvs_on_organisation_id"
  end

  create_table "rdvs_users", force: :cascade do |t|
    t.bigint "rdv_id"
    t.bigint "user_id"
    t.index ["rdv_id"], name: "index_rdvs_users_on_rdv_id"
    t.index ["user_id"], name: "index_rdvs_users_on_user_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "short_name"
  end

  create_table "super_admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "address"
    t.string "phone_number"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.integer "caisse_affiliation"
    t.string "affiliation_number"
    t.integer "family_situation"
    t.integer "number_of_children"
    t.integer "logement"
    t.bigint "responsible_id"
    t.datetime "deleted_at"
    t.string "birth_name"
    t.text "notes"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["responsible_id"], name: "index_users_on_responsible_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "target_url", null: false
    t.string "secret"
    t.bigint "organisation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organisation_id"], name: "index_webhook_endpoints_on_organisation_id"
  end

  add_foreign_key "absences", "agents"
  add_foreign_key "absences", "organisations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agents", "services"
  add_foreign_key "file_attentes", "rdvs"
  add_foreign_key "file_attentes", "users"
  add_foreign_key "lieux", "organisations"
  add_foreign_key "motif_libelles", "services"
  add_foreign_key "motifs", "organisations"
  add_foreign_key "motifs", "services"
  add_foreign_key "plage_ouvertures", "agents"
  add_foreign_key "plage_ouvertures", "lieux"
  add_foreign_key "plage_ouvertures", "organisations"
  add_foreign_key "rdvs", "motifs"
  add_foreign_key "rdvs", "organisations"
  add_foreign_key "users", "users", column: "responsible_id"
  add_foreign_key "webhook_endpoints", "organisations"
end
