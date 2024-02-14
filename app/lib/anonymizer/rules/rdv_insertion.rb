class Anonymizer::Rules::RdvInsertion
  TRUNCATED_TABLES = %w[
    active_storage_attachments
    active_storage_blobs
    active_storage_variant_records
    agent_roles
    schema_migrations
    ar_internal_metadata
  ].freeze

  RULES = {
    agents: {
      class_name: "Agent",
      anonymized_column_names: %w[email first_name last_name],
      non_anonymized_column_names: %w[super_admin last_sign_in_at created_at updated_at last_webhook_update_received_at rdv_solidarites_agent_id],
    },
    agents_rdvs: {
      class_name: "AgentRdv",
      non_anonymized_column_names: %w[created_at updated_at agent_id rdv_id],
    },
    archives: {
      class_name: "Archive",
      anonymized_column_names: %w[archiving_reason],
      non_anonymized_column_names: %w[created_at updated_at user_id department_id],
    },
    configurations: {
      class_name: "Configuration",
      anonymized_column_names: %w[
        template_rdv_title_override
        template_rdv_title_by_phone_override
        template_user_designation_override
        template_rdv_purpose_override
        phone_number
      ],
      non_anonymized_column_names: %w[
        number_of_days_between_periodic_invites
        day_of_the_month_periodic_invites
        position
        department_position
        created_at
        updated_at
        invitation_formats
        convene_user
        number_of_days_before_action_required
        invite_to_user_organisations_only
        rdv_with_referents
        motif_category_id
        file_configuration_id
        organisation_id
      ],
    },
    departments: {
      class_name: "Department",
      anonymized_column_names: %w[name phone_number email region pronoun capital],
      non_anonymized_column_names: %w[created_at updated_at display_in_stats carnet_de_bord_deploiement_id],
    },
    file_configurations: {
      class_name: "FileConfiguration",
      anonymized_column_names: %w[
        sheet_name
        title_column
        first_name_column
        last_name_column
        role_column
        email_column
        phone_number_column
        birth_date_column
        birth_name_column
        address_first_field_column
        address_second_field_column
        address_third_field_column
        address_fourth_field_column
        address_fifth_field_column
        affiliation_number_column
        pole_emploi_id_column
        nir_column
        department_internal_id_column
        rights_opening_date_column
        organisation_search_terms_column
        referent_email_column
        tags_column
      ],
      non_anonymized_column_names: %w[created_at updated_at],
    },
    invitations: {
      class_name: "Invitation",
      anonymized_column_names: %w[link help_phone_number rdv_solidarites_token],
      non_anonymized_column_names: %w[
        format
        sent_at
        user_id
        created_at
        updated_at
        clicked
        department_id
        rdv_solidarites_lieu_id
        rdv_context_id
        valid_until
        reminder
        uuid
        rdv_with_referents
      ],
    },
    invitations_organisations: {
      class_name: "InvitationOrganisation",
      non_anonymized_column_names: %w[organisation_id invitation_id],
    },
    lieux: {
      class_name: "Lieu",
      anonymized_column_names: %w[name address phone_number],
      non_anonymized_column_names: %w[created_at updated_at rdv_solidarites_lieu_id organisation_id last_webhook_update_received_at],
    },
    messages_configurations: {
      class_name: "MessagesConfiguration",
      anonymized_column_names: %w[sender_city direction_names letter_sender_name signature_lines help_address sms_sender_name],
      non_anonymized_column_names: %w[
        created_at
        updated_at
        display_europe_logos
        display_department_logo
        display_pole_emploi_logo
        organisation_id
      ],
    },
    motif_categories: {
      class_name: "MotifCategory",
      anonymized_column_names: %w[short_name name],
      non_anonymized_column_names: %w[
        template_id
        rdv_solidarites_motif_category_id
        created_at
        updated_at
        optional_rdv_subscription
        leads_to_orientation
      ],
    },
    motifs: {
      class_name: "Motif",
      anonymized_column_names: %w[name instruction_for_rdv],
      non_anonymized_column_names: %w[
        rdv_solidarites_service_id
        rdv_solidarites_motif_id
        reservable_online
        deleted_at
        collectif
        location_type
        last_webhook_update_received_at
        organisation_id
        created_at
        updated_at
        follow_up
        motif_category_id
      ],
    },
    notifications: {
      class_name: "Notification",
      anonymized_column_names: %w[event],
      non_anonymized_column_names: %w[
        sent_at
        created_at
        updated_at
        rdv_solidarites_rdv_id
        format
        participation_id
      ],
    },
    organisations_webhook_endpoints: {
      class_name: "OrganisationsWebhookEndpoint",
      non_anonymized_column_names: %w[organisation_id webhook_endpoint_id],
    },
    orientations: {
      class_name: "Orientation",
      anonymized_column_names: %w[orientation_type],
      non_anonymized_column_names: %w[user_id organisation_id agent_id starts_at ends_at created_at updated_at],
    },
    parcours_documents: {
      class_name: "ParcoursDocument",
      non_anonymized_column_names: %w[department_id user_id agent_id type created_at updated_at],
    },
    participations: {
      class_name: "Participation",
      non_anonymized_column_names: %w[
        user_id
        rdv_id
        status
        rdv_solidarites_participation_id
        created_at
        updated_at
        rdv_context_id
        created_by
        convocable
      ],
    },
    rdv_contexts: {
      class_name: "RdvContext",
      non_anonymized_column_names: %w[
        status
        user_id
        created_at
        updated_at
        motif_category_id
        closed_at
      ],
    },
    users: {
      class_name: "User",
      anonymized_column_names: %w[
        affiliation_number
        first_name
        last_name
        address
        phone_number
        email
        title
        birth_date
        birth_name
        nir
        pole_emploi_id
        carnet_de_bord_carnet_id
      ],
      non_anonymized_column_names: %w[
        rights_opening_date
        rdv_solidarites_user_id
        department_internal_id
        uid
        role
        created_at
        updated_at
        deleted_at
        last_webhook_update_received_at
        created_through
      ],
    },
    rdvs: {
      class_name: "Rdv",
      anonymized_column_names: %w[context address],
      non_anonymized_column_names: %w[
        rdv_solidarites_rdv_id
        starts_at
        duration_in_min
        cancelled_at
        uuid
        created_by
        status
        created_at
        updated_at
        organisation_id
        last_webhook_update_received_at
        motif_id
        lieu_id
        users_count
        max_participants_count
      ],
    },
    referent_assignations: {
      class_name: "ReferentAssignation",
      non_anonymized_column_names: %w[agent_id user_id],
    },
    stats: {
      class_name: "Stat",
      non_anonymized_column_names: %w[
        users_count
        users_count_grouped_by_month
        rdvs_count
        rdvs_count_grouped_by_month
        sent_invitations_count
        sent_invitations_count_grouped_by_month
        average_time_between_invitation_and_rdv_in_days
        average_time_between_invitation_and_rdv_in_days_by_month
        rate_of_users_oriented_in_less_than_30_days
        rate_of_users_oriented_in_less_than_30_days_by_month
        agents_count
        created_at
        updated_at
        rate_of_autonomous_users
        rate_of_autonomous_users_grouped_by_month
        statable_type
        statable_id
        rate_of_no_show_for_convocations
        rate_of_no_show_for_convocations_grouped_by_month
        rate_of_no_show_for_invitations
        rate_of_no_show_for_invitations_grouped_by_month
        rate_of_users_oriented
        rate_of_users_oriented_grouped_by_month
        users_with_rdv_count
      ],
    },
    tag_organisations: {
      class_name: "TagOrganisation",
      non_anonymized_column_names: %w[organisation_id tag_id created_at updated_at],
    },
    tag_users: {
      class_name: "TagUser",
      non_anonymized_column_names: %w[user_id tag_id created_at updated_at],
    },
    tags: {
      class_name: "Tag",
      anonymized_column_names: %w[value],
      non_anonymized_column_names: %w[created_at updated_at],
    },
    templates: {
      class_name: "Template",
      anonymized_column_names: %w[rdv_title rdv_title_by_phone rdv_purpose user_designation rdv_subject custom_sentence punishable_warning],
      non_anonymized_column_names: %w[model display_mandatory_warning created_at updated_at],
    },
    organisations: {
      class_name: "Organisation",
      anonymized_column_names: %w[name phone_number email slug logo_filename safir_code],
      non_anonymized_column_names: %w[
        rdv_solidarites_organisation_id
        created_at
        updated_at
        department_id
        last_webhook_update_received_at
        independent_from_cd
      ],
    },
    users_organisations: {
      class_name: "UserOrganisation",
      non_anonymized_column_names: %w[user_id organisation_id created_at updated_at],
    },
    webhook_endpoints: {
      class_name: "WebhookEndpoint",
      anonymized_column_names: %w[url secret signature_type],
      non_anonymized_column_names: %w[created_at updated_at subscriptions],
    },
    webhook_receipts: {
      class_name: "WebhookReceipt",
      non_anonymized_column_names: %w[resource_id webhook_endpoint_id timestamp created_at updated_at resource_model],
    },
  }.with_indifferent_access.freeze
end
