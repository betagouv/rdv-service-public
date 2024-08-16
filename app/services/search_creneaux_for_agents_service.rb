class SearchCreneauxForAgentsService < SearchCreneauxForAgentsBase
  def perform
    lieux.map { build_result(_1) }.compact # NOTE: LOOP 1 over lieux.
  end

  def next_availability_by_lieu
    lieux.map do |lieu|
      availability = next_availability(lieu)
      if availability
        OpenStruct.new(lieu: lieu, next_availability: availability)
      end
    end.compact
  end

  def next_availability(lieu = nil)
    NextAvailabilityService.find(@form.motif, lieu, all_agents, from: @form.date_range.first)
  end

  def build_result(lieu = nil)
    lieu ||= lieux.first
    # utiliser les ids des agents pour ne pas faire de requêtes supplémentaire
    creneaux = SlotBuilder.available_slots(@form.motif, lieu, @form.date_range, all_agents)
    creneaux = creneaux.uniq { [_1.starts_at, _1.agent] }
    availability = next_availability(lieu)
    return nil if creneaux.empty? && availability.nil?

    OpenStruct.new(lieu: lieu, next_availability: availability, creneaux: creneaux)
  end

  def lieux
    return [] if @form.motif.blank?

    return @lieux unless @lieux.nil?

    @lieux = @form.organisation.lieux
    @lieux = \
      if @form.lieu_ids.present?
        @lieux.where(id: @form.lieu_ids)
      else
        @lieux.for_motif(@form.motif)
      end

    @lieux = @lieux.where(id: PlageOuverture.where(agent_id: all_agents).select(:lieu_id)) if all_agents.present?

    @lieux = @lieux.ordered_by_name
    @lieux
  end
end
