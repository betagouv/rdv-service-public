class SearchCreneauxWithoutLieuForAgentsService < SearchCreneauxForAgentsBase
  def perform
    # utiliser les ids des agents pour ne pas faire de requêtes supplémentaire
    # Utilise le date_range.end + 1 pour chercher la date suivante du créneau affiché
    next_availability = @form.motifs.map do |motif|
      NextAvailabilityService.find(motif, nil, all_agents, from: @form.date_range.end + 1.day)
    end.first
    creneaux = @form.motifs.map do |motif|
      SlotBuilder.available_slots(motif, nil, @form.date_range, all_agents)
    end.flatten
    creneaux = creneaux.uniq { [_1.starts_at, _1.agent] }
    return nil if creneaux.empty? && next_availability.nil?

    OpenStruct.new(lieu: nil, next_availability: next_availability, creneaux: creneaux)
  end
end
