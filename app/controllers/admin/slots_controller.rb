class Admin::SlotsController < AgentAuthController
  def index
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)

    # Dans ce cadre là, nous n'avons qu'un lieu, et donc une structure en résultat de l'appel à ce service.
    # TODO reprendre le service pour le sortir du format `background_job` et proposer 2 méthodes publiques
    # - une pour construire la liste des lieux
    # - une pour le cas où nous avons déjà un lieu
    # À terme, ça pourrait également être un calcul plus réduit. Dans le cas de la recherche sur plusieurs lieux, nous avons besoin de connaitre la prochaine dispo, pas TOUTES les dispo
    @search_result = search_result

    @motifs = Agent::MotifPolicy::Scope.apply(current_agent, Motif)
      .where(organisation: current_organisation)
      .active.ordered_by_name
    @services = Service.where(id: @motifs.pluck(:service_id).uniq)
    @form.service_id = @services.first.id if @services.count == 1
    @agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .complete.active.ordered_by_last_name
    @lieux = Agent::LieuPolicy::Scope.apply(current_agent, current_organisation.lieux).enabled.ordered_by_name
  end

  private

  def search_result
    if @form.motif.requires_lieu?
      if @form.motif.individuel?
        SearchCreneauxForAgentsService.perform_with(@form).first
      else
        SearchRdvCollectifForAgentsService.new(@form).slot_search
      end
    else
      SearchCreneauxWithoutLieuForAgentsService.perform_with(@form)
    end
  end
end
