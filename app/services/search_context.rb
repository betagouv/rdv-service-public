class SearchContext
  def initialize(user:, query_params: {})
    @user = user
    @query_params = query_params
  end

  def geo_search
    Users::GeoSearch.new(departement: departement, city_code: city_code, street_ban_id: street_ban_id)
  end

  def lieu
    @lieu ||= lieu_id.blank? ? nil : Lieu.find(lieu_id)
  end

  def start_date
    Time.zone.today
  end

  def creneaux
    @creneaux ||= creneaux_search.creneaux
      .uniq(&:starts_at) # On n'affiche qu'un créneau par horaire, même si plusieurs agents sont dispos
  end

  def available_collective_rdvs
    @available_collective_rdvs ||= creneaux_search.available_collective_rdvs
  end

  def creneaux_search
    creneaux_search_for(lieu, date_range, first_matching_motif)
  end

  def first_matching_motif
    matching_motifs.first
  end

  def referent_agents
    @referent_agents ||= retrieve_referent_agents
  end

  def follow_up?
    referent_ids.present?
  end

  def date_range
    start_date..(start_date + 6.days)
  end

  def filter_motifs(available_motifs)
    motifs = available_motifs
    motifs = motifs.where(follow_up: follow_up?)
    motifs = motifs.with_availability_for_lieux([lieu.id]) if lieu.present?
    motifs = motifs.with_availability_for_agents(referent_agents.map(&:id)) if follow_up?
    motifs
  end

  private

  def referent_ids
    raise NoMethodError
  end

  def matching_motifs
    raise NoMethodError
  end

  def departement
    raise NoMethodError
  end

  def city_code
    raise NoMethodError
  end

  def street_ban_id
    raise NoMethodError
  end

  def lieu_id
    raise NoMethodError
  end

  def creneaux_search_for(lieu, date_range, motif)
    CreneauxSearch::ForUser.new(
      user: @user,
      motif: motif,
      lieu: lieu,
      date_range: date_range,
      geo_search: geo_search
    )
  end

  def retrieve_referent_agents
    return [] if @referent_ids.blank? || @user.nil?

    @user.referent_agents.where(id: @referent_ids)
  end
end
