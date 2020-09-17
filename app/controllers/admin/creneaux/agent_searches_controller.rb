class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  def index
    @user = User.find(params[:user_id]) if params[:user_id]
    @form = build_agent_creneaux_search_form
    @next_availability_by_lieux = {}
    @form.lieux.each do |lieu|
      @next_availability_by_lieux[lieu.id] = FindAvailabilityService
        .perform_with(@form.motif.name, lieu, Date.today, for_agents: true)
    end
    @creneaux_by_lieux = @form.lieux.each_with_object({}) do |lieu, creneaux_by_lieux|
      creneaux_by_lieux[lieu.id] = CreneauxBuilderService
        .perform_with(@form.motif.name, lieu, @form.date_range, for_agents: true, agent_ids: @form.agent_ids)
    end
    respond_to do |format|
      format.html do
        @organisation = current_organisation # TODO: remove
        @motifs = policy_scope(Motif).active.ordered_by_name
        @agents = policy_scope(Agent).complete.active.order_by_last_name
        @lieux = policy_scope(Lieu).ordered_by_name
      end
      format.js
    end
  end

  private

  def build_agent_creneaux_search_form
    AgentCreneauxSearchForm.new(
      organisation_id: current_organisation.id,
      **search_params
    )
  end

  def search_params
    {
      motif_id: params[:motif_id],
      from_date: params[:from_date],
      agent_ids: params[:agent_ids]&.reject(&:blank?) || [],
      user_ids: params[:user_ids]&.reject(&:blank?) || [],
      lieu_ids: params[:lieu_ids]&.reject(&:blank?) || []
    }
  end
end
