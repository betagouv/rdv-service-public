module User::Ants
  extend ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  def self.validate_ants_pre_demande_number(user:, ants_pre_demande_number:, ignore_benign_errors:)
    return if ignore_benign_errors || ants_pre_demande_number.blank?

    appointment = AntsApi::Appointment.first(application_id: ants_pre_demande_number, timeout: 4)
    return if appointment.nil?

    user.add_benign_error(warning_message(appointment))
  rescue AntsApi::Appointment::InvalidApplicationError => e
    user.errors.add(:base, e.message)
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
end
