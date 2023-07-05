# frozen_string_literal: true

module Ants
  class SyncAppointmentJob < ApplicationJob
    def perform(ants_pre_demande_number)
      @ants_pre_demande_number = ants_pre_demande_number

      obsolete_appointments = appointments_in_ants_api - appointments_in_our_database

      obsolete_appointments.each(&:delete!)

      missing_appointments = appointments_in_our_database - appointments_in_ants_api

      missing_appointments.each(&:create!)
    end

    private

    def appointments_in_ants_api
      @appointments_in_ants_api ||= AntsApiAppointment.list(@ants_pre_demande_number).select do |appointment|
        appointment.management_url.include?(Domain::RDV_MAIRIE.host_name)
      end
    end

    def appointments_in_our_database
      @appointments_in_our_database = Rdv.not_cancelled.joins(:users, :organisation).where(
        users: { ants_pre_demande_number: @ants_pre_demande_number },
        organisations: { verticale: :rdv_mairie }
      ).map do |rdv|
        AppointmentSerializerAndListener.serialize_for_ants_api(@ants_pre_demande_number, rdv)
      end
    end
  end
end
