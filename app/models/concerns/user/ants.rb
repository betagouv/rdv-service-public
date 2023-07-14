# frozen_string_literal: true

module User::Ants
  extend ActiveSupport::Concern

  def validate_ants_pre_demande_number(user, ants_pre_demande_number)
    appointment = AntsApi::Appointment.first(application_id: ants_pre_demande_number)
    if appointment
      user.add_benign_error(
        I18n.t(
          "activerecord.warnings.models.user.ants_pre_demande_number_already_used",
          management_url: appointment.management_url,
          meeting_point: appointment.meeting_point
        )
      )
    end
  end
end
