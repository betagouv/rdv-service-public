module User::Ants
  extend ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  def self.validate_ants_pre_demande_number(user:, ants_pre_demande_number:, ignore_benign_errors:)
    return if ants_pre_demande_number.blank?

    ants_pre_demande_number = ants_pre_demande_number.upcase

    unless ants_pre_demande_number.match?(/\A[A-Z0-9]{10}\z/)
      user.errors.add(:ants_pre_demande_number, :invalid_format)
      return
    end

    application_hash = AntsApi.status(application_id: ants_pre_demande_number, timeout: 4)

    status = application_hash["status"]

    if status == "validated"

      if application_hash["appointments"].any?
        appointment = OpenStruct.new(application_hash["appointments"].first)
        user.add_benign_error(warning_message(appointment)) unless ignore_benign_errors
      end

    else
      user.errors.add(:ants_pre_demande_number, AntsApi::ERROR_STATUSES.fetch(status))
    end
  rescue AntsApi::ApiRequestError, Typhoeus::Errors::TimeoutError => e
    # Si l'API de l'ANTS est fiable, donc si elle renvoie une erreur ou un timeout,
    # on préfère bloquer la réservation et logguer l'erreur.
    user.errors.add(:ants_pre_demande_number, :unexpected_api_error)
    Sentry.capture_exception(e)
  end

  def self.warning_message(appointment)
    translate(
      "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
      management_url: appointment.management_url,
      meeting_point: appointment.meeting_point
    )
  end

  def syncable_with_ants?
    return false if ants_pre_demande_number.blank?

    status = AntsApi.status(application_id: ants_pre_demande_number, timeout: 4)["status"]
    status == "validated"
  end
end
