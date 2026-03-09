module CreneauxSearch::Calculator
  class << self
    # méthode publique
    def available_slots(motif:, lieu:, date_range:, agents: [], duration_in_min: nil)
      datetime_range = CreneauxSearch::Range.ensure_date_range_with_time(date_range)
      plage_ouvertures = plage_ouvertures_for(motif, lieu, datetime_range, agents)
      import_absences_from_caldav(plage_ouvertures.map(&:agent).uniq)

      # Cette méthode découpe les plages d'ouverture en fonction des absences, rdvs, et jours fériés
      free_times_po = FreeTimesFromPlageOuvertureAndBusyTimes.new(
        plage_ouvertures,
        datetime_range,
        work_on_off_days: motif.organisation.territory.work_on_sunday? # La colonne `work_on_sunday` indique aussi que les agents travaillent les jours fériés
      ).perform

      # Convention de nommage:
      #
      # - available/disponible : moments où l'agent déclare pouvoir assurer des rendez-vous
      #   (via une plage d'ouverture, qui sera peut-être renommée en disponibilités), mais il est possible que l'agent soit occupé par une absence, un rendez-vous ou autre
      # - busy/occupé : moment où l'agent est pris par un rendez-vous, une indispo, un congé, ou un évènement
      # - free/libre : moment où l'agent est effectivement libre: il est disponible et il n'est pas occupé
      #
      # pour résumer : "available times" - "busy times" = "free times"
      SplitFreeTimeRangesIntoCreneaux.new(free_times_po, motif, duration_in_min:).perform(datetime_range)
    end

    def plage_ouvertures_for(motif, lieu, datetime_range, agents)
      scope = PlageOuverture.not_expired
        .merge(motif.plage_ouvertures)
        .in_range(datetime_range)
        .includes(:agent)
        .where(agent: Agent.excluding_pending_invitation)

      scope = scope.where(agent: agents) if agents&.any?
      scope = scope.where(lieu: lieu) if lieu.present?
      scope
    end

    def import_absences_from_caldav(agents)
      agents.each do |agent|
        if agent.caldav_configured?
          Caldav::ImportAbsencesFromCaldavJob.perform_later(agent.id)
        end
      end
    end
  end
end
