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

ActiveRecord::Schema.define(version: 2022_03_05_160339) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

  create_enum :agents_rdv_notifications_level, [
    "all",
    "others",
    "soon",
    "none",
  ], force: :cascade

  create_enum :location_type, [
    "public_office",
    "home",
    "phone",
  ], force: :cascade

  create_enum :rdv_status, [
    "unknown",
    "waiting",
    "seen",
    "excused",
    "revoked",
    "noshow",
  ], force: :cascade

  create_enum :sms_provider, [
    "netsize",
    "send_in_blue",
    "contact_experience",
    "sfr_mail2sms",
    "clever_technologies",
    "orange_contact_everyone",
  ], force: :cascade

  create_enum :user_created_through, [
    "unknown",
    "agent_creation",
    "user_sign_up",
    "franceconnect_sign_up",
    "user_relative_creation",
    "agent_creation_api",
  ], force: :cascade

  create_enum :user_invited_through, [
    "unknown",
    "devise_email",
    "external",
  ], force: :cascade

  create_table "absences", force: :cascade do |t|
    t.bigint "agent_id"
    t.string "title", null: false
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "recurrence"
    t.date "first_day", null: false
    t.time "start_time", null: false
    t.date "end_day", null: false
    t.time "end_time", null: false
    t.boolean "expired_cached", default: false, null: false
    t.datetime "recurrence_ends_at"
    t.index "tsrange((first_day)::timestamp without time zone, recurrence_ends_at, '[]'::text)", name: "index_absences_on_tsrange_first_day_recurrence_ends_at", using: :gist
    t.index ["agent_id"], name: "index_absences_on_agent_id"
    t.index ["end_day"], name: "index_absences_on_end_day"
    t.index ["expired_cached"], name: "index_absences_on_expired_cached"
    t.index ["first_day"], name: "index_absences_on_first_day"
    t.index ["organisation_id"], name: "index_absences_on_organisation_id"
    t.index ["recurrence"], name: "index_absences_on_recurrence", where: "(recurrence IS NOT NULL)"
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
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_teams", force: :cascade do |t|
    t.bigint "team_id"
    t.bigint "agent_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["agent_id"], name: "index_agent_teams_on_agent_id"
    t.index ["team_id"], name: "index_agent_teams_on_team_id"
  end

  create_table "agent_territorial_roles", force: :cascade do |t|
    t.bigint "agent_id"
    t.bigint "territory_id"
    t.index ["agent_id"], name: "index_agent_territorial_roles_on_agent_id"
    t.index ["territory_id"], name: "index_agent_territorial_roles_on_territory_id"
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
    t.string "email_original"
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.text "tokens"
    t.boolean "allow_password_change", default: false
    t.enum "rdv_notifications_level", default: "soon", enum_type: "agents_rdv_notifications_level"
    t.text "search_terms"
    t.integer "unknown_past_rdv_count", default: 0
    t.boolean "display_saturdays", default: false
    t.index "to_tsvector('simple'::regconfig, COALESCE(search_terms, ''::text))", name: "index_agents_search_terms", using: :gin
    t.index ["confirmation_token"], name: "index_agents_on_confirmation_token", unique: true
    t.index ["email"], name: "index_agents_on_email", unique: true
    t.index ["invitation_token"], name: "index_agents_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_agents_on_invitations_count"
    t.index ["invited_by_id"], name: "index_agents_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_agents_on_invited_by_type_and_invited_by_id"
    t.index ["last_name"], name: "index_agents_on_last_name"
    t.index ["reset_password_token"], name: "index_agents_on_reset_password_token", unique: true
    t.index ["service_id"], name: "index_agents_on_service_id"
    t.index ["uid", "provider"], name: "index_agents_on_uid_and_provider", unique: true
  end

  create_table "agents_organisations", force: :cascade do |t|
    t.bigint "agent_id"
    t.bigint "organisation_id"
    t.string "level", default: "basic", null: false
    t.index ["agent_id"], name: "index_agents_organisations_on_agent_id"
    t.index ["level"], name: "index_agents_organisations_on_level"
    t.index ["organisation_id", "agent_id"], name: "index_agents_organisations_on_organisation_id_and_agent_id", unique: true
    t.index ["organisation_id"], name: "index_agents_organisations_on_organisation_id"
  end

  create_table "agents_rdvs", force: :cascade do |t|
    t.bigint "agent_id"
    t.bigint "rdv_id"
    t.index ["agent_id", "rdv_id"], name: "index_agents_rdvs_on_agent_id_and_rdv_id", unique: true
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
    t.index ["rdv_id", "user_id"], name: "index_file_attentes_on_rdv_id_and_user_id", unique: true
    t.index ["rdv_id"], name: "index_file_attentes_on_rdv_id"
    t.index ["user_id"], name: "index_file_attentes_on_user_id"
  end

  create_table "lieux", force: :cascade do |t|
    t.string "name"
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.float "latitude"
    t.float "longitude"
    t.string "phone_number"
    t.string "phone_number_formatted"
    t.boolean "enabled", default: true, null: false
    t.index ["enabled"], name: "index_lieux_on_enabled"
    t.index ["name"], name: "index_lieux_on_name"
    t.index ["organisation_id"], name: "index_lieux_on_organisation_id"
  end

  create_table "motifs", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "default_duration_in_min", default: 30, null: false
    t.bigint "organisation_id"
    t.boolean "reservable_online", default: false, null: false
    t.integer "min_booking_delay", default: 1800
    t.integer "max_booking_delay", default: 7889238
    t.datetime "deleted_at"
    t.bigint "service_id"
    t.text "restriction_for_rdv"
    t.text "instruction_for_rdv"
    t.boolean "for_secretariat", default: false
    t.integer "old_location_type", default: 0, null: false
    t.boolean "follow_up", default: false
    t.string "visibility_type", default: "visible_and_notified", null: false
    t.string "sectorisation_level", default: "departement"
    t.text "custom_cancel_warning_message"
    t.boolean "collectif", default: false
    t.enum "location_type", default: "public_office", null: false, enum_type: "location_type"
    t.index "to_tsvector('simple'::regconfig, (COALESCE(name, (''::text)::character varying))::text)", name: "index_motifs_name_vector", using: :gin
    t.index ["deleted_at"], name: "index_motifs_on_deleted_at"
    t.index ["location_type"], name: "index_motifs_on_location_type"
    t.index ["name", "organisation_id", "location_type", "service_id"], name: "index_motifs_on_name_scoped", unique: true, where: "(deleted_at IS NULL)"
    t.index ["name"], name: "index_motifs_on_name"
    t.index ["organisation_id"], name: "index_motifs_on_organisation_id"
    t.index ["reservable_online"], name: "index_motifs_on_reservable_online"
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
    t.string "human_id", default: "", null: false
    t.string "website"
    t.string "email"
    t.bigint "territory_id", null: false
    t.index ["human_id", "territory_id"], name: "index_organisations_on_human_id_and_territory_id", unique: true, where: "((human_id)::text <> ''::text)"
    t.index ["name", "territory_id"], name: "index_organisations_on_name_and_territory_id", unique: true
    t.index ["name"], name: "index_organisations_on_name"
    t.index ["territory_id"], name: "index_organisations_on_territory_id"
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
    t.boolean "expired_cached", default: false
    t.datetime "recurrence_ends_at"
    t.text "search_terms"
    t.index "to_tsvector('simple'::regconfig, COALESCE(search_terms, ''::text))", name: "index_plage_ouvertures_search_terms", using: :gin
    t.index "tsrange((first_day)::timestamp without time zone, recurrence_ends_at, '[]'::text)", name: "index_plage_ouvertures_on_tsrange_first_day_recurrence_ends_at", using: :gist
    t.index ["agent_id"], name: "index_plage_ouvertures_on_agent_id"
    t.index ["expired_cached"], name: "index_plage_ouvertures_on_expired_cached"
    t.index ["first_day"], name: "index_plage_ouvertures_on_first_day"
    t.index ["lieu_id"], name: "index_plage_ouvertures_on_lieu_id"
    t.index ["organisation_id"], name: "index_plage_ouvertures_on_organisation_id"
    t.index ["recurrence"], name: "index_plage_ouvertures_on_recurrence", where: "(recurrence IS NOT NULL)"
  end

  create_table "rdv_events", force: :cascade do |t|
    t.bigint "rdv_id", null: false
    t.string "event_type"
    t.string "event_name"
    t.datetime "created_at"
    t.index ["rdv_id"], name: "index_rdv_events_on_rdv_id"
  end

  create_table "rdvs", force: :cascade do |t|
    t.datetime "starts_at", null: false
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "cancelled_at"
    t.bigint "motif_id"
    t.integer "sequence", default: 0, null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.string "old_location"
    t.integer "created_by", default: 0
    t.text "context"
    t.bigint "lieu_id"
    t.enum "status", default: "unknown", null: false, enum_type: "rdv_status"
    t.datetime "ends_at", null: false
    t.index "tsrange(starts_at, ends_at, '[)'::text)", name: "index_rdvs_on_tsrange_starts_at_ends_at", using: :gist
    t.index ["created_by"], name: "index_rdvs_on_created_by"
    t.index ["ends_at"], name: "index_rdvs_on_ends_at"
    t.index ["lieu_id"], name: "index_rdvs_on_lieu_id"
    t.index ["motif_id"], name: "index_rdvs_on_motif_id"
    t.index ["organisation_id"], name: "index_rdvs_on_organisation_id"
    t.index ["starts_at"], name: "index_rdvs_on_starts_at"
    t.index ["status"], name: "index_rdvs_on_status"
    t.index ["updated_at"], name: "index_rdvs_on_updated_at"
  end

  create_table "rdvs_users", force: :cascade do |t|
    t.bigint "rdv_id"
    t.bigint "user_id"
    t.boolean "send_lifecycle_notifications", null: false
    t.boolean "send_reminder_notification", null: false
    t.index ["rdv_id", "user_id"], name: "index_rdvs_users_on_rdv_id_and_user_id", unique: true
    t.index ["rdv_id"], name: "index_rdvs_users_on_rdv_id"
    t.index ["user_id"], name: "index_rdvs_users_on_user_id"
  end

  create_table "sector_attributions", force: :cascade do |t|
    t.bigint "sector_id", null: false
    t.bigint "organisation_id", null: false
    t.string "level", null: false
    t.bigint "agent_id"
    t.index ["agent_id"], name: "index_sector_attributions_on_agent_id"
    t.index ["organisation_id"], name: "index_sector_attributions_on_organisation_id"
    t.index ["sector_id"], name: "index_sector_attributions_on_sector_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.string "departement"
    t.string "name", null: false
    t.string "human_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "territory_id", null: false
    t.index ["departement"], name: "index_sectors_on_departement"
    t.index ["human_id", "territory_id"], name: "index_sectors_on_human_id_and_territory_id", unique: true
    t.index ["human_id"], name: "index_sectors_on_human_id"
    t.index ["territory_id"], name: "index_sectors_on_territory_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "short_name"
    t.index "lower((name)::text)", name: "index_services_on_lower_name", unique: true
    t.index "lower((short_name)::text)", name: "index_services_on_lower_short_name", unique: true
    t.index ["name"], name: "index_services_on_name"
  end

  create_table "super_admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "territory_id"
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "search_terms"
    t.index "to_tsvector('simple'::regconfig, COALESCE(search_terms, ''::text))", name: "index_teams_search_terms", using: :gin
    t.index ["name", "territory_id"], name: "index_teams_on_name_and_territory_id", unique: true
    t.index ["territory_id"], name: "index_teams_on_territory_id"
  end

  create_table "territories", force: :cascade do |t|
    t.string "departement_number", default: "", null: false
    t.string "name"
    t.string "phone_number"
    t.string "phone_number_formatted"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.enum "sms_provider", enum_type: "sms_provider"
    t.json "sms_configuration"
    t.boolean "has_own_sms_provider", default: false
    t.string "api_options", default: [], null: false, array: true
    t.boolean "enable_notes_field", default: false
    t.boolean "enable_caisse_affiliation_field", default: false
    t.boolean "enable_affiliation_number_field", default: false
    t.boolean "enable_family_situation_field", default: false
    t.boolean "enable_number_of_children_field", default: false
    t.boolean "enable_logement_field", default: false
    t.index ["departement_number"], name: "index_territories_on_departement_number", unique: true, where: "((departement_number)::text <> ''::text)"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "organisation_id"
    t.bigint "user_id"
    t.integer "logement"
    t.text "notes"
    t.index ["organisation_id", "user_id"], name: "index_user_profiles_on_organisation_id_and_user_id", unique: true
    t.index ["organisation_id"], name: "index_user_profiles_on_organisation_id"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
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
    t.bigint "responsible_id"
    t.datetime "deleted_at"
    t.string "birth_name"
    t.string "email_original"
    t.string "phone_number_formatted"
    t.boolean "notify_by_sms", default: true
    t.boolean "notify_by_email", default: true
    t.datetime "last_sign_in_at"
    t.string "franceconnect_openid_sub"
    t.boolean "logged_once_with_franceconnect"
    t.integer "invite_for"
    t.string "city_code"
    t.string "post_code"
    t.string "city_name"
    t.enum "invited_through", default: "unknown", enum_type: "user_invited_through"
    t.enum "created_through", default: "unknown", enum_type: "user_created_through"
    t.text "search_terms"
    t.index "to_tsvector('simple'::regconfig, COALESCE(search_terms, ''::text))", name: "index_users_search_terms", using: :gin
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_through"], name: "index_users_on_created_through"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["phone_number_formatted"], name: "index_users_on_phone_number_formatted"
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
    t.json "virtual_attributes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "target_url", null: false
    t.string "secret"
    t.bigint "organisation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "subscriptions", default: ["rdv", "absence", "plage_ouverture"], array: true
    t.index ["organisation_id"], name: "index_webhook_endpoints_on_organisation_id"
  end

  create_table "zones", force: :cascade do |t|
    t.string "level"
    t.string "city_name"
    t.string "city_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "sector_id", null: false
    t.string "street_name"
    t.string "street_ban_id"
    t.index ["sector_id"], name: "index_zones_on_sector_id"
  end

  add_foreign_key "absences", "agents"
  add_foreign_key "absences", "organisations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agents", "services"
  add_foreign_key "file_attentes", "rdvs"
  add_foreign_key "file_attentes", "users"
  add_foreign_key "lieux", "organisations"
  add_foreign_key "motifs", "organisations"
  add_foreign_key "motifs", "services"
  add_foreign_key "plage_ouvertures", "agents"
  add_foreign_key "plage_ouvertures", "lieux"
  add_foreign_key "plage_ouvertures", "organisations"
  add_foreign_key "rdv_events", "rdvs"
  add_foreign_key "rdvs", "lieux"
  add_foreign_key "rdvs", "motifs"
  add_foreign_key "rdvs", "organisations"
  add_foreign_key "sector_attributions", "agents"
  add_foreign_key "users", "users", column: "responsible_id"
  add_foreign_key "webhook_endpoints", "organisations"
end
