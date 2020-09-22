class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  def index
    @user = User.find(params[:user_id]) if params[:user_id]
    @form = build_agent_creneaux_search_form
    @search_results = SearchCreneauxForAgentsService.perform_with(@form) \
      if (params[:commit].present? || request.format.js?) && @form.valid?
    respond_to do |format|
      format.html do
        @motifs = policy_scope(Motif).active.ordered_by_name
        @agents = policy_scope(Agent).complete.active.order_by_last_name
        @lieux = policy_scope(Lieu).ordered_by_name
      end
      format.js do
        skip_policy_scope # TODO: improve pundit checks for creneaux
      end
    end
  end

  private

  def build_agent_creneaux_search_form
    AgentCreneauxSearchForm.new(
      organisation_id: current_organisation.id,
      motif_id: params[:motif_id],
      from_date: params[:from_date],
      user_id: params[:user_id].presence,
      agent_ids: params[:agent_ids]&.reject(&:blank?) || [],
      lieu_ids: params[:lieu_ids]&.reject(&:blank?) || []
    )
  end
end
