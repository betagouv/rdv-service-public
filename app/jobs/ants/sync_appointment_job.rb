module Ants
  class SyncAppointmentJob < ApplicationJob
    # empêcher deux jobs parallèles avec le même application_id
    include GoodJob::ActiveJobExtensions::Concurrency
    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "#{self.class.name}-rdv-#{arguments.last[:application_id]}" }
    )
    # useful to debug tests and avoid retries
    # discard_on(StandardError) { |_job, ex| raise ex }

    def perform(application_id:)
      ants_status = AntsApi.status(application_id:, timeout: 4)

      return false unless ants_status["status"] == "validated"

      ants_appointments = ants_status["appointments"]
        .select { _1["management_url"].include?("rdv") } # TODO

      rdv = Rdv.joins(:users)
        .where(users: { ants_pre_demande_number: application_id })
        .where.not(status: Rdv::CANCELLED_STATUSES)
        .first

      # on ne fait rien si les infos sont déjà identiques
      return true if ants_appointments == [rdv&.serialize_for_ants_api]

      # on déclenche la suppression des appointments existants dans tous les cas, qu’il s’agisse d’une mise à jour ou d’une suppression
      # en effet l’API de l’ANTS ne permet pas de faire de mises à jour, on fait donc un delete puis un update
      ants_appointments.each do |appointment|
        AntsApi.delete(
          application_id:,
          **appointment.symbolize_keys.slice(:meeting_point, :appointment_date, :meeting_point_id)
        )
      end

      # S’il n’y a aucun RDV non-annulé dans notre DB, on s’arrête ici. Il n’y a plus aucun appointment ANTS
      return unless rdv

      AntsApi.create(application_id:, **rdv.serialize_for_ants_api)
    end
  end
end
