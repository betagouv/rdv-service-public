module User::Ants
  extend ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  def self.validate_ants_pre_demande_number(user:, ants_pre_demande_number:, ignore_benign_errors:)
    return if ants_pre_demande_number.blank?

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
    # Si l'api de l'ANTS renvoie une erreur ou un timeout, on ne veut pas bloquer la prise de rendez-vous
    # pour l'usager, donc on considère le numéro comme valide.
    Sentry.capture_exception(e)
    nil
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
      user.errors.add(:base, "Ce numéro de pré-demande ANTS correspond à un dossier déjà instruit")
    when "unknown"
      user.errors.add(:base, "Ce numéro de pré-demande ANTS est inconnu")
    when "expired"
      user.errors.add(:base, "Ce numéro de pré-demande ANTS a expiré")
    else
      user.errors.add(:base, "Ce numéro de pré-demande ANTS est invalide")
    end
  end
end
