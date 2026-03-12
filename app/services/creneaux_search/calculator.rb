class CreneauxSearch::Calculator
  def self.available_slots(date_range:, motif:, lieu: nil, agents: [], duration_in_min: nil, old_calculator: nil)
    old_calculator = ENV["USE_OLD_CRENEAUX_SEARCH_CALCULATOR"] if old_calculator.nil?
    if old_calculator
      CreneauxSearch::OldCalculator.available_slots(motif:, lieu:, date_range:, agents:, duration_in_min:)
    else
      new(motif:, lieu:, date_range:, agents:, duration_in_min:).available_slots
    end
  end

  def initialize(motif:, lieu:, date_range:, agents:, duration_in_min:)
    @motif = motif
    @lieu = lieu
    @date_range = date_range
    @agents = agents
    @duration_in_min = duration_in_min
  end

  def available_slots
    import_absences_from_caldav

    @datetime_range = CreneauxSearch::Range.ensure_date_range_with_time(@date_range)

    plage_ouvertures.map do |plage_ouverture|
      # Convention de nommage:
      #
      # - available/disponible : moments où l'agent déclare pouvoir assurer des rendez-vous
      #                          (via une plage d'ouverture, qui sera peut-être renommée en disponibilités)
      #                          mais il est possible que l'agent soit occupé par une absence, un rendez-vous ou autre chose
      # - busy/occupé : moment où l'agent est pris par un rendez-vous, une indispo, un congé, ou un évènement
      # - free/libre : moment où l'agent est effectivement libre: il est disponible et il n'est pas occupé
      #
      # pour résumer : "free times" = "available times" - "busy times"
      #
      free_times = FreeTimesFromPlageOuvertureAndBusyTimes.new(
        @datetime_range,
        plage_ouverture,
        work_on_off_days: @motif.organisation.territory.work_on_sunday? # La colonne `work_on_sunday` indique aussi que les agents travaillent les jours fériés
      ).perform

      SplitFreeTimeRangesIntoCreneaux.new(free_times, @motif, plage_ouverture, duration_in_min: @duration_in_min).perform(@datetime_range)
    end.flatten
  end

  private

  def plage_ouvertures
    scope = PlageOuverture.not_expired
      .merge(@motif.plage_ouvertures)
      .in_range(@datetime_range)
      .includes(:agent)
      .where(agent: Agent.excluding_pending_invitation)

    scope = scope.where(agent: @agents) if @agents.present?
    scope = scope.where(lieu: @lieu) if @lieu.present?
    scope
  end

  def import_absences_from_caldav
    plage_ouvertures.map(&:agent).uniq.each do |agent|
      if agent.caldav_configured?
        Caldav::ImportAbsencesFromCaldavJob.perform_later(agent.id)
      end
    end
  end
end
