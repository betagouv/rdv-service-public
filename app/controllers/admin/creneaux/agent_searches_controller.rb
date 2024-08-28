class Admin::Creneaux::AgentSearchesController < AgentAuthController
  before_action :set_form

  helper_method :motif_selected?

  def index
    if form_submitted?
      if requires_lieu?
        results_for_lieu
      else
        results_without_lieu
      end
    else
      prepare_form
    end
  end

  private

  def results_without_lieu
    next_availability = CreneauxSearch::ForAgent.new(@form).next_availability

    if next_availability.present?
      skip_policy_scope # TODO: improve pundit checks for creneaux
      redirect_to admin_organisation_slots_path(current_organisation, creneaux_search_params)
    else
      @next_availabilities = []
      prepare_form
    end
  end

  def results_for_lieu
    # nécessaire pour le `else`
    # et pour le cas où nous sommes sur un
    # motif public_office pour vérifier qu'il n'y
    # qu'un lieu
    set_search_results
    if only_one_lieu?
      skip_policy_scope # TODO: improve pundit checks for creneaux
      redirect_to admin_organisation_slots_path(current_organisation, creneaux_search_params)
    else
      prepare_form
    end
  end

  def form_submitted?
    params[:commit].present? && motif_selected?
  end

  def prepare_form
    @motifs = Agent::MotifPolicy::Scope.apply(current_agent, current_organisation.motifs).active.ordered_by_name
    @services = Service.where(id: @motifs.pluck(:service_id).uniq)
    @form.service_id = @services.first.id if @services.count == 1
    @teams = current_organisation.territory.teams
    @agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .complete.active.ordered_by_last_name
    @lieux = Agent::LieuPolicy::Scope.apply(current_agent, current_organisation.lieux).enabled.ordered_by_name
  end

  def motif_selected?
    @form.motif.present?
  end

  def only_one_lieu?
    requires_lieu? && @next_availabilities&.count == 1
  end

  def requires_lieu?
    @form.motif&.requires_lieu?
  end

  def set_form
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)
  end

  def set_search_results
    if @form.valid?
      # Un RDV collectif peut-il avoir lieu à domicile ou au téléphone ?
      @next_availabilities = if @form.motif.individuel?
                               CreneauxSearch::ForAgent.new(@form).next_availabilities
                             else
                               SearchRdvCollectifForAgentsService.new(@form).next_availabilities
                             end
    end
  end

  def creneaux_search_params
    creneaux_search_params = helpers.creneaux_search_params(@form)
    if only_one_lieu?
      creneaux_search_params.merge(lieu_ids: [@next_availabilities.first.lieu.id])
    else
      creneaux_search_params
    end
  end
end
