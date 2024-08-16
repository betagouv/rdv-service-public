class SearchCreneauxWithoutLieuForAgentsService < SearchCreneauxForAgentsBase
  def perform
    # utiliser les ids des agents pour ne pas faire de requêtes supplémentaire
    creneaux = SlotBuilder.available_slots(@form.motif, nil, @form.date_range, all_agents)
    creneaux = creneaux.uniq { [_1.starts_at, _1.agent] }
    return nil if creneaux.empty? && next_availability.nil?

    OpenStruct.new(lieu: nil, next_availability: next_availability, creneaux: creneaux)
  end

  def next_availability
    @next_availability = NextAvailabilityService.find(@form.motif, nil, all_agents, from: @form.date_range.first)
  end
end
