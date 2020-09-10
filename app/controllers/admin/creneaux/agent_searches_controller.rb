class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  def index
    skip_policy_scope
    @user = User.find(params[:user_id]) if params[:user_id]
    respond_to do |format|
      format.html do
        @organisation = current_organisation
        @motifs = policy_scope(Motif).active.ordered_by_name
        @agents = policy_scope(Agent).complete.active.order_by_last_name
        @lieux = policy_scope(Lieu).ordered_by_name
      end
      format.js do
        @agent_search = Creneau::AgentSearch.new(filter_params)
        @agent_search.organisation_id = current_organisation.id
        set_params
        @lieux = @agent_search.lieux
        @next_availability_by_lieux = {}
        @lieux.each do |lieu|
          @next_availability_by_lieux[lieu.id] = FindAvailabilityService.perform_with(@motif.name, lieu, Date.today, for_agents: true)
        end

        @creneaux_by_lieux = @lieux.each_with_object({}) do |lieu, creneaux_by_lieux|
          creneaux_by_lieux[lieu.id] = CreneauxBuilderService.perform_with(@motif.name, lieu, @date_range, for_agents: true, agent_ids: @agent_ids)
        end
      end
    end
  end

  def by_lieu
    skip_authorization

    @agent_search = Creneau::AgentSearch.new(by_lieu_params)
    @agent_search.organisation_id = current_organisation.id
    set_params
    @lieu = @agent_search.lieu
    @next_availability = FindAvailabilityService.perform_with(@motif.name, @lieu, Date.today, for_agents: true)
    @creneaux = CreneauxBuilderService.perform_with(@motif.name, @lieu, @date_range, for_agents: true, agent_ids: @agent_ids, user_ids: @user_ids)
  end

  def set_params
    @date_range = @agent_search.from_date..(@agent_search.from_date + 6.days)
    @motif = @agent_search.motif
    @agent_ids = @agent_search.agent_ids
    @user_ids = @agent_search.user_ids
  end

  private

  def filter_params
    params.require(:creneau_agent_search).permit(:motif_id, :from_date, agent_ids: [], lieu_ids: [])
  end

  def by_lieu_params
    params.permit(:lieu_id, :motif_id, :from_date, agent_ids: [], user_ids: [])
  end
end
