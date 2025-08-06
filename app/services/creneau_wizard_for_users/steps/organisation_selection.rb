class CreneauWizardForUsers::Steps::OrganisationSelection
  def initialize(web_search_context)
    @context = web_search_context
  end

  # Retourne une liste d'organisations et leur prochaine dispo, ordonnées par date de prochaine dispo
  def next_availability_by_motifs_organisations
    @next_availability_by_motifs_organisations ||= @context.matching_motifs.to_h do |motif|
      [motif.organisation, @context.creneaux_search_for(nil, motif).next_availability]
    end.compact.sort_by(&:last).to_h
  end
end
