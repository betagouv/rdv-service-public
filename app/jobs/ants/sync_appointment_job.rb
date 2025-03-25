module Ants
  class MissingMeetingPointId < StandardError; end

  class SyncAppointmentJob < ApplicationJob
    # empêcher deux jobs parallèles avec le même ants_pre_demande_number
    include GoodJob::ActiveJobExtensions::Concurrency
    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "#{self.class.name}-rdv-#{arguments.last[:ants_pre_demande_number]}" }
    )
    discard_on(MissingMeetingPointId) { |_job, error| Sentry.capture_exception(error) }
    # useful to debug tests and avoid retries
    # discard_on(StandardError) { |_job, ex| raise ex }

    queue_as :latency_5m

    def perform(ants_pre_demande_number:, obsolete_meeting_point_id: nil)
      @ants_pre_demande_number = ants_pre_demande_number
      @obsolete_meeting_point_id = obsolete_meeting_point_id

      if meeting_point_id.nil?
        raise MissingMeetingPointId, "aucun RDV trouvé pour le numéro ANTS '#{ants_pre_demande_number}'"
      end

      ants_status = AntsApi.status(
        ants_pre_demande_number: stripped_ants_pre_demande_number,
        meeting_point_id:,
        timeout: 4
      )

      return false unless ants_status["status"] == "validated"

      # on n’utilise pas de regex ci-dessous pour éviter un faux-positif de Brakeman
      protocol = Rails.env.production? ? "https" : "http"
      @ants_appointments = ants_status["appointments"].select do |appointment|
        appointment["management_url"].start_with?("#{protocol}://#{Domain::RDV_MAIRIE.host_name}")
      end

      return true unless needs_synchronization?

      # on déclenche la suppression des appointments existants dans tous les cas, qu’il s’agisse d’une mise à jour ou d’une suppression
      # en effet l’API de l’ANTS ne permet pas de faire de mises à jour, on fait donc un delete puis un create
      @ants_appointments.each do |appointment|
        AntsApi.delete(
          ants_pre_demande_number: stripped_ants_pre_demande_number,
          meeting_point_id:, # les appointments retournés par status ne contiennent pas le meeting_point_id
          **appointment.symbolize_keys.slice(:meeting_point, :appointment_date)
        )
      end

      # S’il n’y a aucun RDV non-annulé dans notre DB, on s’arrête ici. Il n’y a plus aucun appointment ANTS
      return unless upcoming_rdv

      AntsApi.create(ants_pre_demande_number: stripped_ants_pre_demande_number, **upcoming_rdv_serialized_to_ants_appointment)
    end

    def capture_sentry_warning_for_retry?(exception)
      if exception.is_a?(Typhoeus::Errors::TimeoutError)
        false
      else
        super
      end
    end

    private

    attr_reader :ants_pre_demande_number

    def upcoming_rdv
      @upcoming_rdv ||=
        Rdv
          .joins(:users)
          .joins(motif: [:motif_category])
          .merge(MotifCategory.requires_ants_predemande_number)
          .where(users: { ants_pre_demande_number: [stripped_ants_pre_demande_number, ants_pre_demande_number].uniq })
          .where.not(status: Rdv::CANCELLED_STATUSES)
          .where("starts_at >= ?", Time.zone.now)
          .order(id: :desc) # choix arbitraire pour éviter un comportement aléatoire
          .first
    end

    def upcoming_rdv_serialized_to_ants_appointment
      @upcoming_rdv_serialized_to_ants_appointment ||= upcoming_rdv&.serialize_for_ants_api
    end

    def stripped_ants_pre_demande_number
      # Nous avons parfois dans les jobs des numéros qui finissent par un espace.
      # Le temps d'investiguer, nous évitons ici que les jobs soient bloqués à cause d'un espace.
      @stripped_ants_pre_demande_number ||= ants_pre_demande_number.strip
    end

    def meeting_point_id
      @meeting_point_id ||=
        if @obsolete_meeting_point_id.present?
          @obsolete_meeting_point_id # utilisé pour les suppressions de participations
        elsif upcoming_rdv&.lieu_id.present?
          return upcoming_rdv.lieu_id.to_s
        else
          # On se replie sur le lieu de n’importe quel RDV associé à ce numéro, même dans le passé
          Lieu
            .joins(rdvs: { users: [], motif: { motif_category: [] } })
            .merge(MotifCategory.requires_ants_predemande_number)
            .where(users: { ants_pre_demande_number: [stripped_ants_pre_demande_number, ants_pre_demande_number].uniq })
            .order("rdvs.id DESC") # choix arbitraire pour éviter un comportement aléatoire
            .first
            &.id
            &.to_s
        end
    end

    def needs_synchronization?
      return false if @ants_appointments.empty? && upcoming_rdv.nil?

      return true if
        @ants_appointments.size > 1 || # ça ne devrait jamais arriver
        (@ants_appointments.empty? && upcoming_rdv.present?) || # il faut créer un rdv
        (@ants_appointments.present? && upcoming_rdv.nil?) # il faut supprimer l’appointment

      compared_attributes = %i[management_url appointment_date meeting_point]
      @ants_appointments.first.symbolize_keys.slice(*compared_attributes) !=
        upcoming_rdv_serialized_to_ants_appointment.slice(*compared_attributes)
    end
  end
end
