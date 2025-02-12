# Cette validation ne peut être utilisée que si le record (ou le form model)
# a un attribut ants_pre_demande_number et inclut le module BenignErrors
#
# Cette validation fait des requêtes HTTP externes à l’API de l’ANTS
#
# cf /docs/interconnexions/ants.md

class AntsPreDemandeNumberStatusValidation < ActiveModel::Validator
  def validate(record)
    raise "You need to include BenignErrors to use #{self.class}" unless record.respond_to?(:add_benign_error)

    ants_pre_demande_number = record.ants_pre_demande_number.upcase

    return unless validate_format(ants_pre_demande_number, record)

    status, appointments = AntsApi.status(ants_pre_demande_number:, timeout: 4).values_at("status", "appointments")

    return unless validate_status_validated(status, record)

    validate_empty_appointments(appointments, record)
  rescue AntsApi::ApiRequestError, Typhoeus::Errors::TimeoutError => e
    # Si l'API de l'ANTS est fiable, donc si elle renvoie une erreur ou un timeout,
    # on préfère bloquer la réservation et logguer l'erreur.
    record.errors.add(:ants_pre_demande_number, "n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
    Rails.logger.error e
    Sentry.capture_exception(e)
  end

  def validate_format(ants_pre_demande_number, record)
    return true if ants_pre_demande_number.match?(/\A[A-Z0-9]{10}\z/)

    record.errors.add(:ants_pre_demande_number, "doit comporter 10 chiffres et lettres")
    false
  end

  def validate_status_validated(status, record)
    return true if status == "validated"

    record.errors.add(:ants_pre_demande_number, AntsApi::ERROR_STATUSES.fetch(status))
    false
  end

  def validate_empty_appointments(appointments, record)
    return true if appointments.empty? || record.ignore_benign_errors

    record.add_benign_error(
      I18n.t(
        "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
        management_url: appointments.first["management_url"],
        meeting_point: appointments.first["meeting_point"]
      ).html_safe
    )
    false
  end
end
