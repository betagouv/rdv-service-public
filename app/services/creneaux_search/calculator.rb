class CreneauxSearch::Calculator
  def self.available_slots(motif:, lieu:, date_range:, agents: [], duration_in_min: nil)
    new(motif:, lieu:, date_range:, agents:, duration_in_min:).available_slots
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
      CreneauxFromPlageOuvertureAndBusyTimes.new(
        @datetime_range,
        plage_ouverture,
        @motif,
        work_on_off_days: @motif.organisation.territory.work_on_sunday?, # La colonne `work_on_sunday` indique aussi que les agents travaillent les jours fériés
        duration_in_min: @duration_in_min
      ).perform
    end.flatten
  end

  private

  def plage_ouvertures
    scope = PlageOuverture.not_expired
      .merge(@motif.plage_ouvertures)
      .in_range(@datetime_range)
      .includes(:agent)
      .where(agent: Agent.excluding_pending_invitation)

    scope = scope.where(agent: @agents) if @agents&.any?
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
