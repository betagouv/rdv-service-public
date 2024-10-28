module Ants
  class SyncAppointmentJob < ApplicationJob
    # empêcher deux jobs parallèles avec le même ants_pre_demande_number
    include GoodJob::ActiveJobExtensions::Concurrency
    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "#{self.class.name}-rdv-#{arguments.last[:ants_pre_demande_number]}" }
    )
    # useful to debug tests and avoid retries
    # discard_on(StandardError) { |_job, ex| raise ex }

    def perform(rdv_attributes: nil, ants_pre_demande_number: nil, **_kwargs)
      return perform_for_ants_pre_demande_number(ants_pre_demande_number) if ants_pre_demande_number

      # Ce code gère la rétrocompatibilité avec l'ancienne signature de ce job
      # TODO: supprimer ce code 2 semaines après le merge
      raise ArgumentError("missing ants_pre_demande_number or rdv_attributes") if rdv_attributes.blank?

      (
        User.where(id: rdv_attributes[:users_ids]).pluck(:ants_pre_demande_number) +
        [rdv_attributes[:obsolete_ants_pre_demande_number]]
      ).compact_blank.each { self.class.perform_later(ants_pre_demande_number: _1) }
    end

    def perform_for_ants_pre_demande_number(ants_pre_demande_number)
      ants_status = AntsApi.status(ants_pre_demande_number:, timeout: 4)

      return false unless ants_status["status"] == "validated"

      # on n’utilise pas de regex ci-dessous pour éviter un faux-positif de Brakeman
      ants_appointments = ants_status["appointments"].select do |appointment|
        protocol = Rails.env.production? ? "https" : "http"
        appointment["management_url"].start_with?("#{protocol}://#{Domain::RDV_MAIRIE.host_name}")
      end

      rdv = Rdv
        .joins(:users)
        .joins(motif: [:motif_category])
        .merge(MotifCategory.requires_ants_predemande_number)
        .where(users: { ants_pre_demande_number: ants_pre_demande_number })
        .where.not(status: Rdv::CANCELLED_STATUSES)
        .where("starts_at >= ?", Time.zone.now)
        .order(id: :desc) # choix arbitraire pour éviter un comportement aléatoire
        .first

      # on ne fait rien si les infos sont déjà identiques
      return true if ants_appointments == [rdv&.serialize_for_ants_api]

      # on déclenche la suppression des appointments existants dans tous les cas, qu’il s’agisse d’une mise à jour ou d’une suppression
      # en effet l’API de l’ANTS ne permet pas de faire de mises à jour, on fait donc un delete puis un update
      ants_appointments.each do |appointment|
        AntsApi.delete(
          ants_pre_demande_number:,
          **appointment.symbolize_keys.slice(:meeting_point, :appointment_date, :meeting_point_id)
        )
      end

      # S’il n’y a aucun RDV non-annulé dans notre DB, on s’arrête ici. Il n’y a plus aucun appointment ANTS
      return unless rdv

      AntsApi.create(ants_pre_demande_number:, **rdv.serialize_for_ants_api)
    end
  end
end
