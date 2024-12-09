# Cette validation ne peut être utilisée que si le record (ou le form model)
# a un attribut ants_pre_demande_number et inclut le module BenignErrors
#
# Cette validation fait des requêtes HTTP externes à l’API de l’ANTS
#
# cf /docs/interconnexions/ants.md

class AntsPreDemandeNumberValidation < ActiveModel::Validator
  def validate(record)
    ants_pre_demande_number = record.ants_pre_demande_number.upcase

    unless ants_pre_demande_number.match?(/\A[A-Z0-9]{10}\z/)
      record.errors.add(:ants_pre_demande_number, "doit comporter 10 chiffres et lettres")
      return
    end

    application_hash = AntsApi.status(ants_pre_demande_number:, timeout: 4)

    status = application_hash["status"]

    if status == "validated"
      if application_hash["appointments"].any?
        appointment = OpenStruct.new(application_hash["appointments"].first)
        record.add_benign_error(warning_message(appointment)) unless record.ignore_benign_errors
      end
    else
      record.errors.add(:ants_pre_demande_number, AntsApi::ERROR_STATUSES.fetch(status))
    end
  rescue AntsApi::ApiRequestError, Typhoeus::Errors::TimeoutError => e
    # Si l'API de l'ANTS est fiable, donc si elle renvoie une erreur ou un timeout,
    # on préfère bloquer la réservation et logguer l'erreur.
    record.errors.add(:ants_pre_demande_number, "n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
    Sentry.capture_exception(e)
  end

  def warning_message(appointment)
    I18n.t(
      "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
      management_url: appointment.management_url,
      meeting_point: appointment.meeting_point
    ).html_safe
  end
end
