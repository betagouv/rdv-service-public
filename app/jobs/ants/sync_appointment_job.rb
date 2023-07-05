# frozen_string_literal: true

module Ants
  class SyncAppointmentJob < ApplicationJob
    def perform(ants_pre_demande_number)
      @ants_pre_demande_number = ants_pre_demande_number

      appointments_in_ants_api = fetch_existing_appointments

      obsolete_appointments = appointments_in_ants_api - appointments_in_our_database

      obsolete_appointments.each do |appointment|
        AntsApi.delete_appointment(@ants_pre_demande_number, appointment)
      end

      missing_appointments = appointments_in_our_database - appointments_in_ants_api

      missing_appointments.each do |appointment|
        AntsApi.create_appointment(@ants_pre_demande_number, appointment)
      end
    end

    private

    def fetch_existing_appointments
      AntsApi.list_appointments(@ants_pre_demande_number).select do |appointment|
        appointment.delete("editor_comment")
        appointment["management_url"].include?(Domain::RDV_MAIRIE.host_name)
      end.map(&:symbolize_keys)
    end

    def appointments_in_our_database
      @appointments_in_our_database = Rdv.not_cancelled.joins(:users, :organisation).where(
        users: { ants_pre_demande_number: @ants_pre_demande_number },
        organisations: { verticale: :rdv_mairie }
      ).map do |rdv|
        AppointmentSerializerAndListener.serialize_for_ants_api(rdv)
      end
    end

    def delete_obsolete_appointment
      if @rdv_attributes[:obsolete_application_id].present?
        obsolete_appointment = AntsApi.find_appointment(
          application_id: @rdv_attributes[:obsolete_application_id],
          management_url: @appointment_data[:management_url]
        )

        AntsApi.delete_appointment(obsolete_appointment) if obsolete_appointment
      end
    end

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
