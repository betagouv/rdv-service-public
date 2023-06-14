# frozen_string_literal: true

module Ants
  module SyncRdv
    extend ActiveSupport::Concern
    include Rails.application.routes.url_helpers

    included do
      after_commit :create_appointment, on: :create, if: -> { organisation.rdv_mairie? }
      before_commit :delete_appointment, on: :destroy, if: -> { organisation.rdv_mairie? }
      after_commit :create_or_delete_appointment, on: :update, if: -> { organisation.rdv_mairie? }
    end

    private

    def create_appointment
      Ants::CreateAppointment.perform_later(rdv_params)
    end

    def delete_appointment
      Ants::DeleteAppointment.perform_later(rdv_params.except(:management_url))
    end

    def create_or_delete_appointment
      return unless saved_change_to_status?

      cancelled? ? delete_appointment : create_appointment
    end

    def rdv_params
      {
        application_id: users.first.ants_pre_demande_number,
        meeting_point: lieu.name,
        appointment_date: starts_at.strftime("%Y-%m-%d %H:%M:%S"),
        management_url: rdvs_short_url(self, host: organisation.domain.host_name)
      }
    end
  end
end
