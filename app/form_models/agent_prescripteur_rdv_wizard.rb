class AgentPrescripteurRdvWizard
  attr_reader :query_params

  def initialize(query_params: {})
    @query_params = query_params
  end

  def motif
    # TODO : add policy scope Motif visible par l'agent current si ouvert à la prescription
    @motif ||= rdv.motif
  end

  def invitation?
    false
  end

  def params_to_selections
    query_params
  end

  def rdv
    return @rdv if @rdv.present?

    if query_params[:rdv_collectif_id].present?
      @rdv = Rdv.collectif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.find(query_params[:rdv_collectif_id])
    else
      @rdv = Rdv.new(query_params.slice(:starts_at, :user_ids, :motif_id, :lieu_id))
      @rdv.participations.map(&:set_default_notifications_flags)
      @rdv.duration_in_min = @rdv.motif&.default_duration_in_min
      @rdv.organisation = motif.organisation
    end
    @rdv
  end

  def create_rdv!
    rdv.agents = [creneau.agent]
    rdv.save!
    rdv
  end

  def creneau
    @creneau ||= Users::CreneauSearch.creneau_for(
      user: @user,
      motif: motif,
      lieu: lieu,
      starts_at: rdv.starts_at,
      geo_search: geo_search
    )
  end

  private

  def lieu
    @lieu ||= Lieu.find_by(id: query_params[:lieu_id])
  end

  def geo_search
    # TODO: add additional arguments if we want to use sectorisation
    @geo_search ||= Users::GeoSearch.new(departement: query_params[:departement])
  end
end
