module Ants
  class SyncAppointmentJob < ApplicationJob
    # prevent concurrent jobs for the same RDV
    include GoodJob::ActiveJobExtensions::Concurrency
    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "#{self.class.name}-rdv-#{arguments.last[:rdv_attributes][:id]}" }
    )

    class << self
      def perform_later_for(rdv)
        # On passe les attributes du RDV au lieu de l'objet active record, au cas où ce dernier serait supprimé
        perform_later(rdv_attributes: rdv_attributes(rdv), appointment_data: rdv.serialize_for_ants_api)
      end

      private

      def rdv_attributes(rdv)
        {
          id: rdv.id,
          status: rdv.status,
          users_ids: rdv.users.ids,
          obsolete_application_id: rdv.obsolete_application_id,
        }
      end
    end

    def perform(rdv_attributes:, appointment_data:)
      @rdv_attributes = rdv_attributes
      @rdv = Rdv.find_by(id: @rdv_attributes[:id])
      # Si le RDV n'est pas supprimé on essaie à nouveau d'extraire les appointment_data, afin d'avoir les données les plus fraiches possibles
      @appointment_data = @rdv.present? ? @rdv.serialize_for_ants_api : appointment_data

      delete_obsolete_appointment

      if rdv_cancelled_or_deleted?
        delete_appointments
      else
        sync_appointments
      end
    end

    private

    def delete_obsolete_appointment
      return if @rdv_attributes[:obsolete_application_id].blank?

      res = AntsApi.find_and_delete(
        application_id: @rdv_attributes[:obsolete_application_id],
        management_url: @appointment_data[:management_url]
      )
      Sentry.set_tags(ants_appointment_deleted: res.present?)
    end

    def rdv_cancelled_or_deleted?
      @rdv.nil? || @rdv_attributes[:status].in?(Rdv::CANCELLED_STATUSES)
    end

    def delete_appointments
      users.each do |user|
        AntsApi.find_and_delete(
          application_id: user.ants_pre_demande_number,
          management_url: @appointment_data[:management_url]
        )
      end
    end

    def sync_appointments
      # L'API de l'ANTS ne fournit pas d'endpoint pour la mise à jour d'un RDV, mais en fournit pour la création et la suppression
      # Pour donc maintenir à jour les infos des RDVs chez l'ANTS, nous sommes obligés de supprimer, et de re-créer les RDVs
      # Toutefois, les RDVs chez l'ANTS avec un status 'consumed', ne sont plus modifiables.
      delete_appointments
      create_appointments
    end

    def create_appointments
      users.each do |user|
        AntsApi.create(
          application_id: user.ants_pre_demande_number,
          management_url: @appointment_data[:management_url],
          appointment_date: @appointment_data[:appointment_date],
          meeting_point: @appointment_data[:meeting_point],
          meeting_point_id: @appointment_data[:meeting_point_id]
        )
      end
    end

    def users
      @users ||= User.where(id: @rdv_attributes[:users_ids]).select do |user|
        syncable_with_ants?(user)
      end
    end

    def syncable_with_ants?(user)
      return false if user.ants_pre_demande_number.blank?

      status = AntsApi.status(application_id: user.ants_pre_demande_number, timeout: 4)["status"]
      status == "validated"
    end
  end
end
