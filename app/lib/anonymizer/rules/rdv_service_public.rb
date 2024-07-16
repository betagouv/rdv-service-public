class Anonymizer::Rules::RdvServicePublic
  TRUNCATED_TABLES = %w[versions good_jobs good_job_executions good_job_settings good_job_batches good_job_processes].freeze

  RULES = {
    users: {
      class_name: "User",
      anonymized_column_names: %w[
        first_name
        last_name
        birth_name
        birth_date
        email
        unconfirmed_email
        address
        address_details
        caisse_affiliation
        affiliation_number
        family_situation
        number_of_children
        phone_number
        phone_number_formatted
        city_code
        post_code
        city_name
        case_number
        logement
        notes
        ants_pre_demande_number
        franceconnect_openid_sub
        encrypted_password
        confirmation_token
        reset_password_token
        invitation_token
        rdv_invitation_token
      ],
      non_anonymized_column_names: %w[
        confirmed_at confirmation_sent_at created_at updated_at created_through invitation_accepted_at invitation_created_at
        text_search_terms deleted_at invitation_limit reset_password_sent_at invitation_sent_at
        invitations_count invited_by_id invited_by_type invited_through notify_by_email notify_by_sms logged_once_with_franceconnect
        rdv_invitation_token_updated_at
      ],
    },
    agents: {
      class_name: "Agent",
      anonymized_column_names: %w[
        first_name last_name
        email
        email_original
        encrypted_password
        unconfirmed_email
        cnfs_secondary_email
        uid
        external_id
        calendar_uid
        last_sign_in_at
        reset_password_token
        confirmation_token
        invitation_token
        tokens
        microsoft_graph_token
        refresh_microsoft_graph_token
        inclusion_connect_open_id_sub
      ],
      non_anonymized_column_names: %w[
        reset_password_sent_at
        confirmed_at
        confirmation_sent_at
        invitation_created_at
        invitation_sent_at
        invitation_accepted_at
        invitation_limit
        invited_by_type
        invited_by_id
        invitations_count
        provider
        rdv_notifications_level
        allow_password_change
        unknown_past_rdv_count
        display_saturdays
        display_cancelled_rdv
        plage_ouverture_notification_level
        absence_notification_level
        outlook_disconnect_in_progress
        account_deletion_warning_sent_at
        connected_with_agent_connect
        deleted_at
        created_at updated_at
      ],
    },
    rdvs: {
      class_name: "Rdv",
      anonymized_column_names: %w[context name],
      non_anonymized_column_names: %w[
        starts_at organisation_id created_at updated_at cancelled_at motif_id uuid
        lieu_id old_location created_by_id created_by_type ends_at max_participants_count users_count status
      ],
    },
    receipts: {
      class_name: "Receipt",
      anonymized_column_names: %w[sms_phone_number email_address content error_message],
      non_anonymized_column_names: %w[
        created_at updated_at error_message event result sms_count sms_provider channel
      ],
    },
    prescripteurs: {
      class_name: "Prescripteur",
      anonymized_column_names: %w[
        first_name last_name email phone_number phone_number_formatted
      ],
      non_anonymized_column_names: %w[created_at updated_at participation_id],
    },
    super_admins: {
      class_name: "SuperAdmin",
      anonymized_column_names: %w[email first_name last_name],
      non_anonymized_column_names: %w[created_at updated_at role],
    },
    organisations: {
      class_name: "Organisation",
      anonymized_column_names: %w[email phone_number],
      non_anonymized_column_names: %w[created_at updated_at name departement horaires human_id website external_id verticale],
    },
    absences: {
      class_name: "Absence",
      anonymized_column_names: %w[title],
      non_anonymized_column_names: %w[created_at updated_at recurrence first_day start_time end_day end_time expired_cached recurrence_ends_at],
    },
    lieux: {
      class_name: "Lieu",
      anonymized_column_names: %w[phone_number phone_number_formatted],
      non_anonymized_column_names: %w[created_at updated_at name old_address latitude longitude old_enabled availability address],
    },
    participations: {
      class_name: "Participation",
      anonymized_column_names: %w[invitation_token],
      non_anonymized_column_names: %w[created_at updated_at send_lifecycle_notifications send_reminder_notification invitation_created_at invitation_sent_at invitation_accepted_at
                                      invitation_limit invited_by_type invited_by_id invitations_count status created_by_id created_by_type created_by_agent_prescripteur],
    },
    plage_ouvertures: {
      class_name: "PlageOuverture",
      anonymized_column_names: %w[title],
      non_anonymized_column_names: %w[created_at updated_at organisation_id first_day start_time end_time recurrence expired_cached recurrence_ends_at],
    },
    webhook_endpoints: {
      class_name: "WebhookEndpoint",
      anonymized_column_names: %w[secret],
      non_anonymized_column_names: %w[created_at updated_at target_url organisation_id subscriptions],
    },
    territories: {
      class_name: "Territory",
      anonymized_column_names: %w[sms_configuration],
      non_anonymized_column_names: %w[
        departement_number name phone_number phone_number_formatted created_at updated_at sms_provider has_own_sms_provider enable_notes_field
        enable_caisse_affiliation_field enable_affiliation_number_field enable_family_situation_field
        enable_number_of_children_field enable_logement_field enable_case_number enable_address_details
        enable_context_field enable_waiting_room_mail_field enable_waiting_room_color_field
        visible_users_throughout_the_territory
      ],
    },

    # Tables sans données personnelles
    agent_roles: { non_anonymized_column_names: %w[access_level] },
    agents_rdvs: { non_anonymized_column_names: %w[outlook_id outlook_create_in_progress] },
    agent_territorial_access_rights: {
      non_anonymized_column_names: %w[allow_to_manage_teams created_at updated_at allow_to_manage_access_rights allow_to_invite_agents],
    },
    teams: { non_anonymized_column_names: %w[name created_at updated_at] },
    motifs: {
      non_anonymized_column_names: %w[
        name color created_at updated_at default_duration_in_min legacy_bookable_publicly
        min_public_booking_delay max_public_booking_delay deleted_at bookable_by
        restriction_for_rdv instruction_for_rdv for_secretariat old_location_type follow_up
        visibility_type sectorisation_level custom_cancel_warning_message collectif location_type
        rdvs_editable_by_user rdvs_cancellable_by_user
      ],
    },
    services: { non_anonymized_column_names: %w[name created_at updated_at short_name] },
    zones: {
      non_anonymized_column_names: %w[
        level city_name city_code created_at updated_at street_name street_ban_id
      ],
    },
    ar_internal_metadata: {
      non_anonymized_column_names: %w[value created_at updated_at],
    },
    territory_services: { non_anonymized_column_names: %w[created_at] },
    agent_services: { non_anonymized_column_names: %w[created_at] },
    agent_teams: {
      non_anonymized_column_names: %w[created_at updated_at],
    },
    sectors: {
      non_anonymized_column_names: %w[departement name human_id created_at updated_at],
    },
    motif_categories: {
      non_anonymized_column_names: %w[name short_name created_at updated_at],
    },
    sector_attributions: {
      non_anonymized_column_names: %w[level],
    },
    file_attentes: {
      non_anonymized_column_names: %w[created_at updated_at notifications_sent last_creneau_sent_at],
    },
    api_calls: {
      class_name: "ApiCall",
      anonymized_column_names: %w[raw_http],
      non_anonymized_column_names: %w[received_at controller_name action_name agent_id],
    },
    exports: {
      non_anonymized_column_names: %w[export_type computed_at expires_at agent_id file_name organisation_ids options created_at updated_at],
    },
  }.with_indifferent_access.freeze
end
