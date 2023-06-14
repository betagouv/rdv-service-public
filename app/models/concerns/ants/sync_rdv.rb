# frozen_string_literal: true

module Ants
  module SyncRdv
    extend ActiveSupport::Concern
    include Rails.application.routes.url_helpers

    included do
      after_commit :create_appointments, on: :create, if: -> { organisation.rdv_mairie? }
      before_commit :delete_appointments, on: :destroy, if: -> { organisation.rdv_mairie? }
      after_commit :create_or_delete_appointments, on: :update, if: -> { organisation.rdv_mairie? }
    end

    private

    def create_appointments
      users.each do |user|
        Ants::CreateAppointment.perform_later(rdv_params(user))
      end
    end

    def delete_appointments
      users.each do |user|
        Ants::DeleteAppointment.perform_later(rdv_params(user).except(:management_url))
      end
    end

    def create_or_delete_appointments
      return unless saved_change_to_status?

      cancelled? ? delete_appointments : create_appointments
    end

    def rdv_params(user)
      {
        application_id: user.ants_pre_demande_number,
        meeting_point: lieu.name,
        appointment_date: starts_at.strftime("%Y-%m-%d %H:%M:%S"),
        management_url: rdvs_short_url(self, host: organisation.domain.host_name),
      }
    end
  end
end
