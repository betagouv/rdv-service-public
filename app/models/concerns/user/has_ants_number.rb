module User::HasAntsNumber
  extend ActiveSupport::Concern

  included do
    # voir Ants::AppointmentSerializerAndListener pour d'autres callbacks
    before_validation -> { ants_pre_demande_number.upcase! }, if: -> { ants_pre_demande_number.present? }

    validate :validate_ants_pre_demande_number, if: -> { ants_pre_demande_number.present? && ants_pre_demande_number_changed? }
  end

  private

  def validate_ants_pre_demande_number
    unless ants_pre_demande_number.match?(/\A[A-Za-z0-9]{10}\z/)
      errors.add(:ants_pre_demande_number, :invalid_format)
      return
    end

    application_hash = AntsApi::Appointment.status(application_id: ants_pre_demande_number, timeout: 4)

    status = application_hash["status"]

    if status == "validated"

      if application_hash["appointments"].any?
        appointment = application_hash["appointments"].first
        warning_message = I18n.t(
          "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
          management_url: appointment["management_url"],
          meeting_point: appointment["meeting_point"]
        ).html_safe # rubocop:disable Rails/OutputSafety
        add_benign_error(warning_message) unless ignore_benign_errors
      end

    else
      errors.add(:ants_pre_demande_number, AntsApi::Appointment::ERROR_STATUSES.fetch(status))
    end
  rescue AntsApi::Appointment::ApiRequestError, Typhoeus::Errors::TimeoutError => e
    # Si l'API de l'ANTS est fiable, donc si elle renvoie une erreur ou un timeout,
    # on préfère bloquer la réservation et logguer l'erreur.
    errors.add(:ants_pre_demande_number, :unexpected_api_error)
    Sentry.capture_exception(e)
  end
end
