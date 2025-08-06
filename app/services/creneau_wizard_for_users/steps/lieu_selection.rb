class CreneauWizardForUsers::Steps::LieuSelection
  def initialize(web_search_context)
    @context = web_search_context
  end

  def shown_lieux
    next_availability_by_lieux.keys
  end

  def next_availability_by_lieux
    return @next_availability_by_lieux if @next_availability_by_lieux

    next_availability_by_lieux = Lieu.with_open_slots_for_motifs(@context.matching_motifs).includes(:organisation).to_h do |lieu|
      next_availability = @context.creneaux_search_for(lieu, @context.matching_motifs.where(organisation: lieu.organisation).first).next_availability
      [lieu, next_availability]
    end.compact

    sort_order = if @context.latitude && @context.longitude
                   proc { |lieu, _| lieu.distance(@context.latitude.to_f, @context.longitude.to_f) }
                 else
                   proc { |_, next_availability| next_availability }
                 end

    @next_availability_by_lieux = next_availability_by_lieux.sort_by(&sort_order).to_h
  end
end
