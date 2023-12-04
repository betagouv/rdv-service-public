class AnonymizerRules
  RULES = {
    users: {
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
        last_sign_in_at
        remember_created_at
        rdv_invitation_token
      ],
      non_anonymized_column_names: %w[
        id confirmed_at confirmation_sent_at created_at updated_at created_through invitation_accepted_at invitation_created_at
        text_search_terms deleted_at invitation_limit reset_password_sent_at responsible_id invitation_sent_at
        invitations_count invited_by_id invited_by_type invited_through notify_by_email notify_by_sms logged_once_with_franceconnect
      ],
    },
    agents: {
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
        current_sign_in_at
        last_sign_in_at
        current_sign_in_ip
        last_sign_in_ip
        reset_password_token
        confirmation_token
        invitation_token
        tokens
        microsoft_graph_token
        refresh_microsoft_graph_token
        remember_created_at
      ],
      non_anonymized_column_names: %w[
        id
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
        sign_in_count
        outlook_disconnect_in_progress
        account_deletion_warning_sent_at
        deleted_at
        created_at updated_at
      ],
    },
    rdvs: {
      anonymized_column_names: %w[context],
      non_anonymized_column_names: %w[
        id starts_at organisation_id created_at updated_at cancelled_at motif_id uuid
        lieu_id old_location created_by ends_at name max_participants_count users_count status
      ],
    },
    receipts: {
      anonymized_column_names: %w[sms_phone_number email_address content],
      non_anonymized_column_names: %w[
        id created_at updated_at error_message event organisation_id
        rdv_id user_id result sms_count sms_provider channel
      ],
    },
    prescripteurs: {
      anonymized_column_names: %w[
        first_name last_name email phone_number phone_number_formatted
      ],
      non_anonymized_column_names: %w[id participation_id user_id created_at updated_at],
    },
    super_admins: {
      anonymized_column_names: %w[email],
      non_anonymized_column_names: %w[id created_at updated_at],
    },
    organisations: {
      anonymized_column_names: %w[email phone_number],
      non_anonymized_column_names: %w[id created_at updated_at name departement horaires human_id website territory_id external_id verticale],
    },
  }.with_indifferent_access.freeze
end
