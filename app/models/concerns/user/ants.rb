# frozen_string_literal: true

module User::Ants
  extend ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  def self.validate_ants_pre_demande_number(user:, ants_pre_demande_number:, ignore_benign_errors:)
    return if ignore_benign_errors || ants_pre_demande_number.blank?

    appointment = find_appointment(ants_pre_demande_number)
    return if appointment.nil?

    user.add_benign_error(warning_message(appointment))
  end

  def self.find_appointment(application_id)
    AntsApi::Appointment.first(application_id: application_id)
  end

  def self.warning_message(appointment)
    translate(
      "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
      management_url: appointment.management_url,
      meeting_point: appointment.meeting_point
    )
  end
end
