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

ActiveRecord::Schema[7.0].define(version: 2024_07_04_145418) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

  create_enum :access_level, [
    "admin",
    "basic",
    "intervenant",
  ], force: :cascade

  create_enum :agents_absence_notification_level, [
    "all",
    "none",
  ], force: :cascade

  create_enum :agents_plage_ouverture_notification_level, [
    "all",
    "none",
  ], force: :cascade

  create_enum :agents_rdv_notifications_level, [
    "all",
    "others",
    "soon",
    "none",
  ], force: :cascade

  create_enum :bookable_by, [
    "agents",
    "agents_and_prescripteurs",
    "everyone",
    "agents_and_prescripteurs_and_invited_users",
  ], force: :cascade

  create_enum :export_type, [
    "rdv_export",
    "participations_export",
  ], force: :cascade

  create_enum :lieu_availability, [
    "enabled",
    "disabled",
    "single_use",
  ], force: :cascade

  create_enum :location_type, [
    "public_office",
    "home",
    "phone",
    "visio",
  ], force: :cascade

  create_enum :rdv_status, [
    "unknown",
    "seen",
    "excused",
    "revoked",
    "noshow",
  ], force: :cascade

  create_enum :receipts_channel, [
    "sms",
    "mail",
    "webhook",
  ], force: :cascade

  create_enum :receipts_result, [
    "processed",
    "sent",
    "delivered",
    "failure",
  ], force: :cascade

  create_enum :role, [
    "legacy_admin",
    "support",
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
    "prescripteur",
  ], force: :cascade

  create_enum :user_invited_through, [
    "devise_email",
    "external",
  ], force: :cascade

  create_enum :verticale, [
    "rdv_insertion",
    "rdv_solidarites",
    "rdv_aide_numerique",
    "rdv_mairie",
  ], force: :cascade

  create_table "absences", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "title", null: false
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
    t.index ["recurrence"], name: "index_absences_on_recurrence", where: "(recurrence IS NOT NULL)"
    t.index ["updated_at"], name: "index_absences_on_updated_at"
  end

  create_table "agent_roles", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "organisation_id", null: false
    t.enum "access_level", default: "basic", null: false, enum_type: "access_level"
    t.index ["access_level"], name: "index_agent_roles_on_access_level"
    t.index ["agent_id"], name: "index_agent_roles_on_agent_id"
    t.index ["organisation_id", "agent_id"], name: "index_agent_roles_on_organisation_id_and_agent_id", unique: true
    t.index ["organisation_id"], name: "index_agent_roles_on_organisation_id"
  end

  create_table "agent_services", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.index ["agent_id", "service_id"], name: "index_agent_services_on_agent_id_and_service_id", unique: true
    t.index ["agent_id"], name: "index_agent_services_on_agent_id"
    t.index ["service_id"], name: "index_agent_services_on_service_id"
  end

  create_table "agent_teams", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "agent_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_agent_teams_on_agent_id"
    t.index ["team_id", "agent_id"], name: "index_agent_teams_primary_keys", unique: true
    t.index ["team_id"], name: "index_agent_teams_on_team_id"
  end

  create_table "agent_territorial_access_rights", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "territory_id", null: false
    t.boolean "allow_to_manage_teams", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "allow_to_manage_access_rights", default: false, null: false
    t.boolean "allow_to_invite_agents", default: false, null: false
    t.index ["agent_id", "territory_id"], name: "index_agent_territorial_access_rights_unique_agent_territory", unique: true
    t.index ["agent_id"], name: "index_agent_territorial_access_rights_on_agent_id"
    t.index ["territory_id"], name: "index_agent_territorial_access_rights_on_territory_id"
  end

  create_table "agent_territorial_roles", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "territory_id", null: false
    t.index ["agent_id", "territory_id"], name: "index_agent_territorial_roles_unique_agent_territory", unique: true
    t.index ["agent_id"], name: "index_agent_territorial_roles_on_agent_id"
    t.index ["territory_id"], name: "index_agent_territorial_roles_on_territory_id"
  end

  create_table "agents", force: :cascade do |t|
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
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
    t.string "email_original"
    t.string "provider", default: "email", null: false
    t.string "uid", default: ""
    t.text "tokens"
    t.boolean "allow_password_change", default: false
    t.enum "rdv_notifications_level", default: "others", enum_type: "agents_rdv_notifications_level"
    t.integer "unknown_past_rdv_count", default: 0
    t.boolean "display_saturdays", default: false, comment: "Indique si l'agent veut que les samedis s'affichent quand il consulte un calendrier (pas forcément le sien). Cela n'affecte pas ce que voient les autres agents. Modifiable par le bouton en bas de la vue calendrier.\n"
    t.boolean "display_cancelled_rdv", default: true, comment: "Indique si l'agent veut que les rdv annulés s'affichent quand il consulte un calendrier (pas forcément le sien). Cela n'affecte pas ce que voient les autres agents. Modifiable par le bouton en bas de la vue calendrier\n"
    t.enum "plage_ouverture_notification_level", default: "all", enum_type: "agents_plage_ouverture_notification_level"
    t.enum "absence_notification_level", default: "all", enum_type: "agents_absence_notification_level"
    t.string "external_id", comment: "The agent's unique and immutable id in the system managing them and adding them to our application"
    t.string "calendar_uid", comment: "the uid used for the url of the agent's ics calendar"
    t.datetime "last_sign_in_at"
    t.text "microsoft_graph_token"
    t.text "refresh_microsoft_graph_token"
    t.string "cnfs_secondary_email"
    t.boolean "outlook_disconnect_in_progress", default: false, null: false
    t.datetime "account_deletion_warning_sent_at", comment: "Quand le compte de l'agent est inactif depuis bientôt deux ans, on lui envoie un mail qui le prévient que sont compte sera bientôt supprimé, et qu'il doit se connecter à nouveau s'il souhaite conserver son compte. On enregistre la date d'envoi de cet email ici pour s'assure qu'on lui laisse un délai d'au moins un mois pour réagir.\n"
    t.string "inclusion_connect_open_id_sub"
    t.boolean "connected_with_agent_connect", default: false, null: false
    t.index ["account_deletion_warning_sent_at"], name: "index_agents_on_account_deletion_warning_sent_at"
    t.index ["calendar_uid"], name: "index_agents_on_calendar_uid", unique: true
    t.index ["confirmation_token"], name: "index_agents_on_confirmation_token", unique: true
    t.index ["email"], name: "index_agents_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["external_id"], name: "index_agents_on_external_id", unique: true
    t.index ["inclusion_connect_open_id_sub"], name: "index_agents_on_inclusion_connect_open_id_sub", unique: true, where: "(inclusion_connect_open_id_sub IS NOT NULL)"
    t.index ["invitation_token"], name: "index_agents_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_agents_on_invitations_count"
    t.index ["invited_by_id"], name: "index_agents_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_agents_on_invited_by_type_and_invited_by_id"
    t.index ["last_name"], name: "index_agents_on_last_name"
    t.index ["reset_password_token"], name: "index_agents_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_agents_on_uid_and_provider", unique: true, where: "(uid IS NOT NULL)"
  end

  create_table "agents_rdvs", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "rdv_id", null: false
    t.text "outlook_id"
    t.boolean "outlook_create_in_progress", default: false, null: false
    t.index ["agent_id", "rdv_id"], name: "index_agents_rdvs_on_agent_id_and_rdv_id", unique: true
    t.index ["agent_id"], name: "index_agents_rdvs_on_agent_id"
    t.index ["rdv_id"], name: "index_agents_rdvs_on_rdv_id"
  end

  create_table "api_calls", force: :cascade do |t|
    t.datetime "received_at", null: false
    t.jsonb "raw_http", null: false
    t.string "controller_name", null: false
    t.string "action_name", null: false
    t.bigint "agent_id", null: false
  end

  create_table "exports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "export_type", null: false, enum_type: "export_type"
    t.datetime "computed_at"
    t.datetime "expires_at", null: false
    t.integer "agent_id", null: false
    t.string "file_name", null: false
    t.jsonb "organisation_ids", null: false
    t.jsonb "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_exports_on_agent_id"
    t.index ["expires_at"], name: "index_exports_on_expires_at"
  end

  create_table "file_attentes", force: :cascade do |t|
    t.bigint "rdv_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_sent", default: 0
    t.datetime "last_creneau_sent_at"
    t.index ["rdv_id", "user_id"], name: "index_file_attentes_on_rdv_id_and_user_id", unique: true
    t.index ["rdv_id"], name: "index_file_attentes_on_rdv_id"
    t.index ["user_id"], name: "index_file_attentes_on_user_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "lieux", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "phone_number"
    t.string "phone_number_formatted"
    t.enum "availability", null: false, comment: "Permet de savoir si le lieu est un lieu normal (enabled), un lieu ponctuel qui sera utilisé pour un seul rdv (single_use), ou un lieu supprimé par soft-delete (disabled). Dans la plupart des cas on s'intéresse uniquement aux lieux enabled\n", enum_type: "lieu_availability"
    t.string "address", null: false
    t.index ["availability"], name: "index_lieux_on_availability"
    t.index ["name"], name: "index_lieux_on_name"
    t.index ["organisation_id"], name: "index_lieux_on_organisation_id"
  end

  create_table "motif_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false, comment: "Le nom \"technique\" de la catégorie de motif, qui permet de l'identifier dans les paramètres de formulaires\"\n"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_motif_categories_on_name", unique: true
    t.index ["short_name"], name: "index_motif_categories_on_short_name", unique: true
  end

  create_table "motif_categories_territories", id: false, force: :cascade do |t|
    t.bigint "motif_category_id", null: false
    t.bigint "territory_id", null: false
    t.index ["motif_category_id", "territory_id"], name: "index_motif_cat_territories_on_motif_cat_id_and_territory_id", unique: true
  end

  create_table "motifs", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "default_duration_in_min", default: 30, null: false
    t.bigint "organisation_id", null: false
    t.integer "min_public_booking_delay", default: 1800, null: false, comment: "Permet de savoir combien de secondes il y aura au minimum entre la prise de rdv par un usager ou un prescripteur et le début du rdv. Par exemple si la valeur est 1800, et qu'il est 10h, le premier rdv qui pourra être pris (s'il y a une plage d'ouverture libre) sera à 10h30, puisque 1800 = 30 x 60. Cela permet à l'agent d'être prévenu suffisamment à l'avance.\n"
    t.integer "max_public_booking_delay", default: 7889238, null: false, comment: "Permet de savoir combien de temps à l'avance il est possible de prendre rdv pour un usager ou un prescripteur. Le délai est mesuré en secondes. Cela évite que des gens prennent des rdv dans trop longtemps, et évite aux agents de s'engager à assurer des rdv alors qu'ils ne connaissent pas leur emploi du temps suffisamment à l'avance.\n"
    t.datetime "deleted_at", comment: "Permet de savoir à quelle date le motif a été soft-deleted\n"
    t.bigint "service_id", null: false
    t.text "restriction_for_rdv", comment: "Instructions à accepter avant la prise du rendez-vous par l'usager\n"
    t.text "instruction_for_rdv", comment: "Indications affichées à l'usager après la confirmation du rendez-vous. Apparait dans le mail de confirmation pour l'usager.\n"
    t.boolean "for_secretariat", default: false, comment: "Permet aux agents du secrétariat d'assurer des rdv pour ce motif\n"
    t.boolean "follow_up", default: false, comment: "Indique s'il s'agit d'un motif de suivi. Si c'est le cas, le rdv pourra uniquement être assuré par un agent référent de l'usager.\n"
    t.string "visibility_type", default: "visible_and_notified", null: false, comment: "Niveau de visibilité du motif pour l'usager. Cette option permet de cacher des rdvs sensibles pour assurer la sécurité d'un usager dont des proches pourraient consulter le téléphone ou le compte RDV Solidarités.\n"
    t.string "sectorisation_level", default: "departement", comment: "Indique à quel point la sectorisation restreint la prise de rdv des usagers pour ce motif. Le niveau \"departement\" indique qu'il n'y a pas de restriction.\n"
    t.text "custom_cancel_warning_message", comment: "Message d'avertissement montré à l'usager en cas d'annulation\n"
    t.boolean "collectif", default: false, comment: "Indique s'il s'agit d'un rdv collectif ou individuel. Un rdv considéré comme individuel peut quand même avoir plusieurs participants, par exemple un parent et son enfant qui renouvellent tous les deux leur carte d'indentité en même temps. Un rdv collectif sera ouvert à plusieurs participants qui ne se connaissent pas entre eux.\n"
    t.enum "location_type", default: "public_office", null: false, comment: "Là où le rdv aura lieu : \"public_office\" pour \"Sur place\" (généralement dans les bureaux de l'organisation), \"phone\" pour au téléphone (l'agent appelle l'usager), \"home\" pour le domicile de l'usager\n", enum_type: "location_type"
    t.boolean "rdvs_editable_by_user", default: true, comment: "Indique si on autorise aux usagers de changer la date du rdv via l'interface web\n"
    t.boolean "rdvs_cancellable_by_user", default: true
    t.bigint "motif_category_id"
    t.enum "bookable_by", default: "agents", null: false, enum_type: "bookable_by"
    t.index "to_tsvector('simple'::regconfig, (COALESCE(name, (''::text)::character varying))::text)", name: "index_motifs_name_vector", using: :gin
    t.index ["collectif"], name: "index_motifs_on_collectif"
    t.index ["deleted_at"], name: "index_motifs_on_deleted_at"
    t.index ["location_type"], name: "index_motifs_on_location_type"
    t.index ["motif_category_id"], name: "index_motifs_on_motif_category_id"
    t.index ["name", "organisation_id", "location_type", "service_id"], name: "index_motifs_on_name_scoped", unique: true, where: "(deleted_at IS NULL)"
    t.index ["name"], name: "index_motifs_on_name"
    t.index ["organisation_id"], name: "index_motifs_on_organisation_id"
    t.index ["service_id"], name: "index_motifs_on_service_id"
    t.index ["visibility_type"], name: "index_motifs_on_visibility_type"
  end

  create_table "motifs_plage_ouvertures", id: false, force: :cascade do |t|
    t.bigint "motif_id", null: false
    t.bigint "plage_ouverture_id", null: false
    t.index ["motif_id", "plage_ouverture_id"], name: "index_motifs_plage_ouvertures_primary_keys", unique: true
    t.index ["motif_id"], name: "index_motifs_plage_ouvertures_on_motif_id"
    t.index ["plage_ouverture_id"], name: "index_motifs_plage_ouvertures_on_plage_ouverture_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "horaires"
    t.string "phone_number"
    t.string "website"
    t.string "email"
    t.bigint "territory_id", null: false
    t.string "external_id", comment: "The organisation's unique and immutable id in the system managing them and adding them to our application"
    t.enum "verticale", default: "rdv_solidarites", null: false, enum_type: "verticale"
    t.index ["external_id", "territory_id"], name: "index_organisations_on_external_id_and_territory_id", unique: true
    t.index ["name", "territory_id"], name: "index_organisations_on_name_and_territory_id", unique: true
    t.index ["name"], name: "index_organisations_on_name"
    t.index ["territory_id"], name: "index_organisations_on_territory_id"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "rdv_id", null: false
    t.bigint "user_id", null: false
    t.boolean "send_lifecycle_notifications", null: false
    t.boolean "send_reminder_notification", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.enum "status", default: "unknown", null: false, enum_type: "rdv_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.string "created_by_type", null: false
    t.boolean "created_by_agent_prescripteur", default: false, null: false
    t.index ["created_by_type", "created_by_id"], name: "index_participations_on_created_by_type_and_created_by_id"
    t.index ["invitation_token"], name: "index_participations_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_participations_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_participations_on_invited_by"
    t.index ["rdv_id", "user_id"], name: "index_participations_on_rdv_id_and_user_id", unique: true
    t.index ["rdv_id"], name: "index_participations_on_rdv_id"
    t.index ["status"], name: "index_participations_on_status"
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "plage_ouvertures", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "title", null: false
    t.bigint "organisation_id", null: false
    t.date "first_day", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "recurrence"
    t.bigint "lieu_id"
    t.boolean "expired_cached", default: false
    t.datetime "recurrence_ends_at"
    t.index "tsrange((first_day)::timestamp without time zone, recurrence_ends_at, '[]'::text)", name: "index_plage_ouvertures_on_tsrange_first_day_recurrence_ends_at", using: :gist
    t.index ["agent_id"], name: "index_plage_ouvertures_on_agent_id"
    t.index ["expired_cached"], name: "index_plage_ouvertures_on_expired_cached"
    t.index ["first_day"], name: "index_plage_ouvertures_on_first_day"
    t.index ["lieu_id"], name: "index_plage_ouvertures_on_lieu_id"
    t.index ["organisation_id"], name: "index_plage_ouvertures_on_organisation_id"
    t.index ["recurrence"], name: "index_plage_ouvertures_on_recurrence", where: "(recurrence IS NOT NULL)"
    t.index ["updated_at"], name: "index_plage_ouvertures_on_updated_at"
  end

  create_table "prescripteurs", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone_number"
    t.string "phone_number_formatted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rdvs", force: :cascade do |t|
    t.datetime "starts_at", null: false
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "cancelled_at"
    t.bigint "motif_id", null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.text "context"
    t.bigint "lieu_id"
    t.datetime "ends_at", null: false
    t.string "name"
    t.integer "max_participants_count"
    t.integer "users_count", default: 0
    t.enum "status", default: "unknown", null: false, enum_type: "rdv_status"
    t.integer "created_by_id"
    t.string "created_by_type", null: false
    t.index "tsrange(starts_at, ends_at, '[)'::text)", name: "index_rdvs_on_tsrange_starts_at_ends_at", using: :gist
    t.index ["created_by_type", "created_by_id"], name: "index_rdvs_on_created_by_type_and_created_by_id"
    t.index ["ends_at"], name: "index_rdvs_on_ends_at"
    t.index ["lieu_id"], name: "index_rdvs_on_lieu_id"
    t.index ["max_participants_count"], name: "index_rdvs_on_max_participants_count"
    t.index ["motif_id"], name: "index_rdvs_on_motif_id"
    t.index ["organisation_id"], name: "index_rdvs_on_organisation_id"
    t.index ["starts_at"], name: "index_rdvs_on_starts_at"
    t.index ["status"], name: "index_rdvs_on_status"
    t.index ["updated_at"], name: "index_rdvs_on_updated_at"
    t.index ["users_count"], name: "index_rdvs_on_users_count"
    t.index ["uuid"], name: "index_rdvs_on_uuid"
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "rdv_id"
    t.bigint "user_id", null: false
    t.string "event", null: false
    t.enum "channel", null: false, enum_type: "receipts_channel"
    t.enum "result", null: false, enum_type: "receipts_result"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sms_provider"
    t.integer "sms_count"
    t.string "content"
    t.string "sms_phone_number"
    t.string "email_address"
    t.bigint "organisation_id", null: false
    t.index ["channel"], name: "index_receipts_on_channel"
    t.index ["created_at"], name: "index_receipts_on_created_at"
    t.index ["event"], name: "index_receipts_on_event"
    t.index ["organisation_id"], name: "index_receipts_on_organisation_id"
    t.index ["rdv_id"], name: "index_receipts_on_rdv_id"
    t.index ["result"], name: "index_receipts_on_result"
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "referent_assignations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "agent_id", null: false
    t.index ["agent_id"], name: "index_referent_assignations_on_agent_id"
    t.index ["user_id", "agent_id"], name: "index_referent_assignations_on_user_id_and_agent_id", unique: true
    t.index ["user_id"], name: "index_referent_assignations_on_user_id"
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
    t.string "name", null: false
    t.string "human_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "territory_id", null: false
    t.index ["human_id", "territory_id"], name: "index_sectors_on_human_id_and_territory_id", unique: true
    t.index ["human_id"], name: "index_sectors_on_human_id"
    t.index ["territory_id"], name: "index_sectors_on_territory_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name", null: false
    t.index "lower((name)::text)", name: "index_services_on_lower_name", unique: true
    t.index "lower((short_name)::text)", name: "index_services_on_lower_short_name", unique: true
    t.index ["name"], name: "index_services_on_name"
  end

  create_table "super_admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.enum "role", default: "support", null: false, enum_type: "role"
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "territory_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "territory_id"], name: "index_teams_on_name_and_territory_id", unique: true
    t.index ["territory_id"], name: "index_teams_on_territory_id"
  end

  create_table "territories", force: :cascade do |t|
    t.string "departement_number", default: "", null: false
    t.string "name"
    t.string "phone_number"
    t.string "phone_number_formatted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "sms_provider", enum_type: "sms_provider"
    t.string "sms_configuration"
    t.boolean "has_own_sms_provider", default: false
    t.boolean "enable_notes_field", default: false
    t.boolean "enable_caisse_affiliation_field", default: false
    t.boolean "enable_affiliation_number_field", default: false
    t.boolean "enable_family_situation_field", default: false
    t.boolean "enable_number_of_children_field", default: false
    t.boolean "enable_logement_field", default: false
    t.boolean "enable_case_number", default: false
    t.boolean "enable_address_details", default: false
    t.boolean "enable_context_field", default: false
    t.boolean "enable_waiting_room_mail_field", default: false
    t.boolean "enable_waiting_room_color_field", default: false
    t.boolean "visible_users_throughout_the_territory", default: false
    t.index ["departement_number"], name: "index_territories_on_departement_number", where: "((departement_number)::text <> ''::text)"
  end

  create_table "territory_services", force: :cascade do |t|
    t.bigint "territory_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.index ["service_id"], name: "index_territory_services_on_service_id"
    t.index ["territory_id", "service_id"], name: "index_territory_services_on_territory_id_and_service_id", unique: true
    t.index ["territory_id"], name: "index_territory_services_on_territory_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "user_id", null: false
    t.index ["organisation_id", "user_id"], name: "index_user_profiles_on_organisation_id_and_user_id", unique: true
    t.index ["organisation_id"], name: "index_user_profiles_on_organisation_id"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "address"
    t.string "phone_number"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
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
    t.string "phone_number_formatted"
    t.boolean "notify_by_sms", default: true
    t.boolean "notify_by_email", default: true
    t.string "franceconnect_openid_sub"
    t.boolean "logged_once_with_franceconnect"
    t.string "city_code"
    t.string "post_code"
    t.string "city_name"
    t.enum "invited_through", default: "devise_email", enum_type: "user_invited_through"
    t.enum "created_through", default: "unknown", null: false, enum_type: "user_created_through"
    t.string "case_number"
    t.string "address_details"
    t.integer "logement"
    t.text "notes"
    t.string "ants_pre_demande_number"
    t.string "rdv_invitation_token"
    t.virtual "text_search_terms", type: :tsvector, as: "(((((setweight(to_tsvector('simple'::regconfig, translate(lower((COALESCE(last_name, ''::character varying))::text), 'àâäéèêëïîôöùûüÿç'::text, 'aaaeeeeiioouuuyc'::text)), 'A'::\"char\") || setweight(to_tsvector('simple'::regconfig, translate(lower((COALESCE(first_name, ''::character varying))::text), 'àâäéèêëïîôöùûüÿç'::text, 'aaaeeeeiioouuuyc'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, translate(lower((COALESCE(birth_name, ''::character varying))::text), 'àâäéèêëïîôöùûüÿç'::text, 'aaaeeeeiioouuuyc'::text)), 'C'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (COALESCE(email, ''::character varying))::text), 'D'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (COALESCE(phone_number_formatted, ''::character varying))::text), 'D'::\"char\")) || setweight(to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text)), 'D'::\"char\"))", stored: true
    t.datetime "rdv_invitation_token_updated_at"
    t.index ["birth_date"], name: "index_users_on_birth_date"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_through"], name: "index_users_on_created_through"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["first_name"], name: "index_users_on_first_name"
    t.index ["franceconnect_openid_sub"], name: "index_users_on_franceconnect_openid_sub", where: "(franceconnect_openid_sub IS NOT NULL)"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["phone_number_formatted"], name: "index_users_on_phone_number_formatted"
    t.index ["rdv_invitation_token"], name: "index_users_on_rdv_invitation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["responsible_id"], name: "index_users_on_responsible_id"
    t.index ["text_search_terms"], name: "index_users_text_search_terms", using: :gin
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.datetime "created_at"
    t.json "virtual_attributes"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "target_url", null: false
    t.string "secret", null: false
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subscriptions", default: ["rdv", "absence", "plage_ouverture"], array: true
    t.index ["organisation_id", "target_url"], name: "index_webhook_endpoints_on_organisation_id_and_target_url", unique: true
    t.index ["organisation_id"], name: "index_webhook_endpoints_on_organisation_id"
  end

  create_table "zones", force: :cascade do |t|
    t.string "level", null: false
    t.string "city_name", null: false
    t.string "city_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sector_id", null: false
    t.string "street_name"
    t.string "street_ban_id"
    t.index ["sector_id"], name: "index_zones_on_sector_id"
  end

  add_foreign_key "absences", "agents"
  add_foreign_key "agent_roles", "agents"
  add_foreign_key "agent_roles", "organisations"
  add_foreign_key "agent_services", "agents"
  add_foreign_key "agent_services", "services"
  add_foreign_key "agent_teams", "agents"
  add_foreign_key "agent_teams", "teams"
  add_foreign_key "agent_territorial_access_rights", "agents"
  add_foreign_key "agent_territorial_access_rights", "territories"
  add_foreign_key "agent_territorial_roles", "agents"
  add_foreign_key "agent_territorial_roles", "territories"
  add_foreign_key "agents_rdvs", "agents"
  add_foreign_key "agents_rdvs", "rdvs"
  add_foreign_key "api_calls", "agents"
  add_foreign_key "exports", "agents"
  add_foreign_key "file_attentes", "rdvs"
  add_foreign_key "file_attentes", "users"
  add_foreign_key "lieux", "organisations"
  add_foreign_key "motif_categories_territories", "motif_categories"
  add_foreign_key "motif_categories_territories", "territories"
  add_foreign_key "motifs", "motif_categories"
  add_foreign_key "motifs", "organisations"
  add_foreign_key "motifs", "services"
  add_foreign_key "motifs_plage_ouvertures", "motifs"
  add_foreign_key "motifs_plage_ouvertures", "plage_ouvertures"
  add_foreign_key "organisations", "territories"
  add_foreign_key "participations", "rdvs"
  add_foreign_key "participations", "users"
  add_foreign_key "plage_ouvertures", "agents"
  add_foreign_key "plage_ouvertures", "lieux"
  add_foreign_key "plage_ouvertures", "organisations"
  add_foreign_key "rdvs", "lieux"
  add_foreign_key "rdvs", "motifs"
  add_foreign_key "rdvs", "organisations"
  add_foreign_key "receipts", "organisations"
  add_foreign_key "receipts", "rdvs"
  add_foreign_key "receipts", "users"
  add_foreign_key "referent_assignations", "agents"
  add_foreign_key "referent_assignations", "users"
  add_foreign_key "sector_attributions", "agents"
  add_foreign_key "sector_attributions", "organisations"
  add_foreign_key "sector_attributions", "sectors"
  add_foreign_key "sectors", "territories"
  add_foreign_key "teams", "territories"
  add_foreign_key "territory_services", "services"
  add_foreign_key "territory_services", "territories"
  add_foreign_key "user_profiles", "organisations"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "users", "users", column: "responsible_id"
  add_foreign_key "webhook_endpoints", "organisations"
  add_foreign_key "zones", "sectors"
end
