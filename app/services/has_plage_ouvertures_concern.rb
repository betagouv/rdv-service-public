module HasPlageOuverturesConcern
  def plages_ouvertures
    @plages_ouvertures ||= PlageOuverture
      .not_expired_for_motif_name_and_lieu(@motif_name, @lieu)
      .where(({ agent_id: @agent_ids } unless @agent_ids.nil?))
      .where(({ motifs: { location_type: @motif_location_type } } if @motif_location_type.present?))
  end
end
