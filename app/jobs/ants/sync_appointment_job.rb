module Ants
  class SyncAppointmentJob < ApplicationJob
    def perform(rdv_attributes:, appointment_data:)
      @rdv_attributes = rdv_attributes
      @rdv = Rdv.find_by(id: @rdv_attributes[:id])
      # Si le RDV n'est pas supprimé on essaie à nouveau d'extraire les appointment_data, afin d'avoir les données les plus fraiches possibles
      @appointment_data = @rdv.present? ? serialize_rdv_to_appointment : appointment_data

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

      obsolete_appointment = AntsApi::Appointment.new(
        application_id: @rdv_attributes[:obsolete_application_id],
        appointment_data: @appointment_data
      )

      obsolete_appointment.delete
    end

    def rdv_cancelled_or_deleted?
      @rdv.nil? || @rdv_attributes[:status].in?(Rdv::CANCELLED_STATUSES)
    end

    def delete_appointments
      appointments.each(&:delete)
    end

    def sync_appointments
      # L'API de l'ANTS ne fournit pas d'endpoint pour la mise à jour d'un RDV, mais en fournit pour la création et la suppression
      # Pour donc maintenir à jour les infos des RDVs chez l'ANTS, nous sommes obligés de supprimer, et de re-créer les RDVs
      # Toutefois, les RDVs chez l'ANTS avec un status 'consumed', ne sont plus modifiables.
      appointments.select(&:syncable?).each do |appointment|
        appointment.delete
        appointment.create
      end
    end

    def appointments
      @appointments = users.map do |user|
        AntsApi::Appointment.new(application_id: user.ants_pre_demande_number, appointment_data: @appointment_data)
      end
    end

    def users
      @users ||= User.where(id: @rdv_attributes[:users_ids]).select do |user|
        user.ants_pre_demande_number.present? # Les agents peuvent créer un rdv sans préciser le numéro de pré-demande ANTS
      end
    end

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
  end
end
