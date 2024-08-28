class CreneauxSearch::ForUser
  def initialize(motif:, date_range: nil, user: nil, lieu: nil, geo_search: nil)
    @user = user
    @motif = motif
    @lieu = lieu
    @date_range = date_range
    @geo_search = geo_search
  end

  def self.creneau_for(motif:, starts_at:, user: nil, lieu: nil, geo_search: nil)
    search = new(
      user: user,
      motif: motif,
      lieu: lieu,
      date_range: (starts_at.to_date..(starts_at + 1.day).to_date),
      geo_search: geo_search
    )

    search.creneaux.select { _1.starts_at == starts_at }.sample
  end

  def next_availability
    return available_collective_rdvs.first if motif.collectif?
    return nil if reduced_date_range.blank?

    CreneauxSearch::NextAvailability.find(motif, @lieu, attributed_agents, from: reduced_date_range.first, to: @motif.end_booking_delay)
  end

  def creneaux
    return available_collective_rdvs if motif.collectif?

    return [] if reduced_date_range.blank?

    CreneauxSearch::Calculator.available_slots(motif, @lieu, reduced_date_range, attributed_agents)
  end

  def available_collective_rdvs
    rdvs = Rdv.collectif_and_available_for_reservation
      .where(motif: motif, lieu: @lieu, starts_at: @motif.start_booking_delay..@motif.end_booking_delay)
      .order(:starts_at)

    rdvs = rdvs.joins(:agents).where(agents: attributed_agents) if attributed_agents.any?
    rdvs
  end

  private

  attr_reader :motif, :date_range

  def reduced_date_range
    @reduced_date_range ||= Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délai min du motif
  end

  def attributed_agents
    @attributed_agents ||= retrieve_attributed_agents
  end

  def retrieve_attributed_agents
    return @user.referent_agents if @user && motif.follow_up?
    return geo_attributed_agents if @geo_search.present? && motif.sectorisation_level_agent?

    []
  end

  def geo_attributed_agents
    @geo_search.attributed_agents_by_organisation[@motif.organisation].presence || []
  end
end
