# frozen_string_literal: true

module Ants
  class SyncEventJob < ApplicationJob
    def self.perform_later_for(rdv)
      # We pass some of the attributes of RDV instead of the Rdv active record object, to avoid an error in case the Rdv is deleted
      perform_later(
        rdv_attributes: { id: rdv.id, status: rdv.status, users_ids: rdv.users.ids },
        appointment_data: rdv.serialize_for_ants_api
      )
    end

    def perform(rdv_attributes:, appointment_data:)
      @rdv_attributes = rdv_attributes
      rdv = Rdv.find_by(id: rdv_attributes[:id])
      # If the RDV is present (not deleted), we serialize now to get the most recent data
      # This way, we'll only be using the appointment_data argument if the RDV has been deleted
      @appointment_data = rdv.present? ? rdv.serialize_for_ants_api : appointment_data

      rdv_cancelled_or_deleted? ? delete_appointments : create_or_update_appointments
    end

    private

    def delete_appointments
      users.each do |user|
        existing_appointment = existing_appointment(user)
        AntsApi.delete_appointment(existing_appointment) if existing_appointment
      end
    end

    def create_or_update_appointments
      users.each do |user|
        existing_appointment = existing_appointment(user)
        AntsApi.delete_appointment(existing_appointment) if existing_appointment

        new_appointment = AntsApi::Appointment.new(application_id: user.ants_pre_demande_number, **@appointment_data)
        AntsApi.create_appointment(new_appointment)
      end
    end

    def users
      @users ||= User.where(id: @rdv_attributes[:users_ids])
    end

    def rdv_cancelled_or_deleted?
      Rdv::CANCELLED_STATUSES.include?(@rdv_attributes[:status]) || !Rdv.exists?(id: @rdv_attributes[:id])
    end

    def existing_appointment(user)
      AntsApi.find_appointment(
        application_id: user.ants_pre_demande_number,
        management_url: @appointment_data[:management_url]
      )
    end
  end
end
