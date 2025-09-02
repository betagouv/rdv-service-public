# Cette validation ne peut être utilisée que si le record (ou le form model)
# a un attribut ants_pre_demande_number et inclut le module BenignErrors
#
# Cette validation fait des requêtes HTTP externes à l’API de l’ANTS
#
# cf /docs/interconnexions/ants.md

class AntsPreDemandeNumberStatusValidation < ActiveModel::Validator
  def validate(record)
    raise "You need to include BenignErrors to use #{self.class}" unless record.respond_to?(:add_benign_error)

    # filet de sécurité : on ne lance pas les vérifications API si le numéro n’est pas présent et valide
    return if
      record.errors[:ants_pre_demande_number].present? ||
      record.ants_pre_demande_number.blank? ||
      !record.ants_pre_demande_number.upcase.match?(AntsPreDemandeNumberFormatValidator::REGEX)

    status, appointments = AntsApi.status(
      ants_pre_demande_number: record.ants_pre_demande_number.upcase,
      meeting_point_id: get_meeting_point_id(record),
      timeout: 4
    ).values_at("status", "appointments")

    return unless validate_status_validated(status, record)

    validate_empty_appointments(appointments, record)
  rescue AntsApi::ApiRequestError, Typhoeus::Errors::TimeoutError => e
    # Si l'API de l'ANTS est fiable, donc si elle renvoie une erreur ou un timeout,
    # on préfère bloquer la réservation et logguer l'erreur.
    record.errors.add(:ants_pre_demande_number, "n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
    Rails.logger.error e
    Sentry.capture_exception(e)
  end

  private

  def get_meeting_point_id(record)
    meeting_point_id = record.respond_to?(:ants_meeting_point_id) ? record.ants_meeting_point_id : nil
    if meeting_point_id.nil?
      Sentry.capture_message("meeting_point_id nil lors de la validation du statut de demande")
    end
    meeting_point_id
  end

  def validate_status_validated(status, record)
    return true if status == "validated"

    record.errors.add(:ants_pre_demande_number, AntsApi::ERROR_STATUSES.fetch(status))
    false
  end

  def validate_empty_appointments(appointments, record)
    return true if appointments.empty? || record.ignore_benign_errors

    record.add_benign_error(
      sanitize(
        I18n.t(
          "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
          management_url: appointments.first["management_url"],
          meeting_point: appointments.first["meeting_point"]
        ),
        attributes: %w[href target]
      )
    )
    false
  end
end
