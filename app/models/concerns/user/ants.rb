# frozen_string_literal: true

module User::Ants
  def validate_ants_pre_demande_number(user:, ants_pre_demande_number:, ignore_benign_errors:)
    return if ignore_benign_errors || ants_pre_demande_number.blank?

    appointment = find_appointment(ants_pre_demande_number)
    return if appointment.nil?

    user.add_benign_error(warning_message(appointment))
  end

  private

  def find_appointment(application_id)
    AntsApi::Appointment.first(application_id: application_id)
  end

  def warning_message(appointment)
    I18n.t(
      "activerecord.warnings.models.user.ants_pre_demande_number_already_used",
      management_url: appointment.management_url,
      meeting_point: appointment.meeting_point
    )
  end
end
