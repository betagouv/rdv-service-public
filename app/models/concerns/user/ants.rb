module User::Ants
  extend ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  PRE_DEMANDE_NUMBER_FORMAT = /\A[A-Za-z0-9]{10}\z/

  def self.validate_ants_pre_demande_number(user:, ants_pre_demande_number:, ignore_benign_errors:)
    return if ants_pre_demande_number.blank?

    unless valid_pre_demande_number?(ants_pre_demande_number)
      user.errors.add(:base, "Numéro de pré-demande doit comporter 10 chiffres et lettres")
      return
    end

    application_hash = AntsApi::Appointment.status(application_id: ants_pre_demande_number, timeout: 4)

    status = application_hash["status"]

    if status == "validated"

      if application_hash["appointments"].any?
        appointment = OpenStruct.new(application_hash["appointments"].first)
        user.add_benign_error(warning_message(appointment)) unless ignore_benign_errors
      end

    else
      user.errors.add(:base, error_message(application_hash["status"]))
    end
  rescue AntsApi::Appointment::ApiRequestError, Typhoeus::Errors::TimeoutError => e
    # Si l'API de l'ANTS est fiable, donc si elle renvoie une erreur ou un timeout,
    # on préfère bloquer la réservation et logguer l'erreur.
    user.errors.add(:base, "Erreur inattendue lors de la validation du numéro de pré-demande, merci de réessayer dans 30 secondes")
    Sentry.capture_exception(e)
  end

  def self.valid_pre_demande_number?(number)
    number.match?(PRE_DEMANDE_NUMBER_FORMAT)
  end

  def self.warning_message(appointment)
    translate(
      "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
      management_url: appointment.management_url,
      meeting_point: appointment.meeting_point
    )
  end

  def self.error_message(status)
    case status
    when "consumed"
      "Ce numéro de pré-demande ANTS correspond à un dossier déjà instruit"
    when "unknown"
      "Ce numéro de pré-demande ANTS est inconnu"
    when "expired"
      "Ce numéro de pré-demande ANTS a expiré"
    else
      "Ce numéro de pré-demande ANTS est invalide"
    end
  end
end
