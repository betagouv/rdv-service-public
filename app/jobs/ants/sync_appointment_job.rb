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
        rdv_attributes = rdv_to_attributes(rdv)
        rdv.users.pluck(:ants_pre_demande_number).compact.uniq.each do |application_id|
          perform_later(rdv_attributes:, application_id:)
        end
      end

      def rdv_to_attributes(rdv)
        {
          id: rdv.id,
          status: rdv.status,
          obsolete_application_id: rdv.obsolete_application_id,
          lieu_id: rdv.lieu.id,
          lieu_name: rdv.lieu.name,
          starts_at: rdv.starts_at.strftime("%Y-%m-%d %H:%M:%S"),
          host_name: rdv.organisation.domain.host_name,
        }.compact
      end
    end

    def perform(rdv_attributes:, application_id:)
      rdv_attributes.symbolize_keys! # TODO: remove?
      @application_id = application_id

      # Si le RDV n'est pas supprimé on essaie à nouveau d'extraire les appointment_data, afin d'avoir les données les plus fraiches possibles
      @rdv = Rdv.find_by(id: rdv_attributes[:id])
      @rdv_attributes = @rdv ? self.class.rdv_to_attributes(@rdv) : rdv_attributes

      delete_obsolete_appointment

      return false unless appointment_validated?

      # L'API de l'ANTS ne fournit pas d'endpoint pour la mise à jour d'un RDV, mais en fournit pour la création et la suppression
      # Pour donc maintenir à jour les infos des RDVs chez l'ANTS, nous sommes obligés de supprimer, et de re-créer les RDVs
      # Toutefois, les RDVs chez l'ANTS avec un status 'consumed', ne sont plus modifiables.
      if rdv_cancelled_or_deleted?
        delete_appointment
      else
        delete_appointment
        create_appointment
      end
    end

    private

    def delete_obsolete_appointment
      return if @rdv_attributes[:obsolete_application_id].blank?

      res = AntsApi.find_and_delete(
        application_id: @rdv_attributes[:obsolete_application_id],
        management_url: management_url_for(@rdv_attributes[:obsolete_application_id])
      )
      Sentry.set_tags(ants_appointment_deleted: res.present?)
    end

    def rdv_cancelled_or_deleted?
      @rdv.nil? || @rdv_attributes[:status].in?(Rdv::CANCELLED_STATUSES)
    end

    def delete_appointment
      # cet appel n’échouera pas si l’appointment n’existe pas encore
      AntsApi.find_and_delete(
        application_id: @application_id,
        management_url: management_url_for(@application_id)
      )
    end

    def create_appointment
      AntsApi.create(
        application_id: @application_id,
        management_url: management_url_for(@application_id),
        appointment_date: @rdv_attributes[:starts_at],
        meeting_point: @rdv_attributes[:lieu_name],
        meeting_point_id: @rdv_attributes[:lieu_id].to_s
      )
    end

    def appointment_validated?
      status = AntsApi.status(application_id: @application_id, timeout: 4)["status"]
      status == "validated"
    end

    def management_url_for(application_id)
      Rails.application.routes.url_helpers.users_rdv_url(
        @rdv_attributes[:id],
        host: @rdv_attributes[:host_name],
        ants_pre_demande_number: application_id
      )
      # ce dernier param GET sera ignoré par notre serveur Rails
      # On l’utilise pour rendre les management_url uniques et
      # respecter la contrainte d’unicité de l’API de l’ANTS
    end
  end
end
