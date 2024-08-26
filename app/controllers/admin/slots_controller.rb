class Admin::SlotsController < AgentAuthController
  def index
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)

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
    if @form.motif.individuel?
      SearchCreneauxForAgentsService.new(@form).build_result
    else
      SearchRdvCollectifForAgentsService.new(@form).slot_search
    end
  end
end
