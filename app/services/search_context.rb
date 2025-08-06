class SearchContext
  def initialize(user:, query_params: {})
    @user = user
    @query_params = query_params
  end

  delegate :creneaux, to: :creneaux_search

  def geo_search
    Users::GeoSearch.new(departement: departement, city_code: city_code, street_ban_id: street_ban_id)
  end

  def lieu
    @lieu ||= lieu_id.blank? ? nil : Lieu.find(lieu_id)
  end

  def start_date
    query_params[:date]&.to_date || Time.zone.today
  end

  def available_collective_rdvs
    @available_collective_rdvs ||= creneaux_search.available_collective_rdvs
  end

  def creneaux_search
    @creneaux_search ||= creneaux_search_for(lieu, first_matching_motif)
  end

  def first_matching_motif
    @first_matching_motif ||= matching_motifs.first
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
    motifs = motifs.with_availability_for_agents(referent_agents.select(:id)) if follow_up?
    motifs
  end

  def creneaux_search_for(lieu, motif)
    duration_in_min = motif.default_duration_in_min
    duration_in_min *= ants_pre_demandes_count.to_i if ants_pre_demandes_count.present?
    CreneauxSearch::ForUser.new(
      user: @user,
      motif: motif,
      lieu: lieu,
      date_range: date_range,
      geo_search: geo_search,
      duration_in_min:
    )
  end

  private

  attr_reader :referent_ids, :lieu_id

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

  def ants_pre_demandes_count
    raise NoMethodError
  end

  def retrieve_referent_agents
    return Agent.none if @referent_ids.blank? || @user.nil?

    @user.referent_agents.where(id: @referent_ids)
  end
end
