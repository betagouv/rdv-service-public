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
      @appointment_data = appointment_data

      rdv_cancelled_or_deleted? ? delete_appointments : create_appointments
    end

    private

    def delete_appointments
      users.each { |user| AntsApi.delete_appointment(appointment(user)) }
    end

    def create_appointments
      users.each { |user| AntsApi.create_appointment(appointment(user)) }
    end

    def users
      @users ||= User.where(id: @rdv_attributes[:users_ids])
    end

    def rdv_cancelled_or_deleted?
      Rdv::CANCELLED_STATUSES.include?(@rdv_attributes[:status]) || !Rdv.exists?(id: @rdv_attributes[:id])
    end

    def appointment(user)
      AntsApi::Appointment.new(application_id: user.ants_pre_demande_number, **@appointment_data)
    end
  end
end
