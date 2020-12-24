class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  # def index
  #   benchmark "benchmark around SearchCreneauxForAgentsService", silence: true do
  #     SearchCreneauxForAgentsService.perform_with(
  #       OpenStruct.new(
  #         motif: Motif.find(800),
  #         agent_ids: nil,
  #         date_range: (Date.today..(Date.today + 6.days)),
  #         organisation: Organisation.find(101),
  #         lieu_ids: []
  #       )
  #     )
  #   end
  # end

  def index
    @form = build_agent_creneaux_search_form
    @search_results = SearchCreneauxForAgentsService.perform_with(@form) \
      if (params[:commit].present? || request.format.js?) && @form.valid?
    respond_to do |format|
      format.html do
        @motifs = policy_scope(Motif).active.ordered_by_name
        @services = policy_scope(Service)
          .where(id: @motifs.pluck(:service_id).uniq)
          .ordered_by_name
        @form.service_id = @services.first.id if @services.count == 1
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
      service_id: params[:service_id],
      motif_id: params[:motif_id],
      from_date: params[:from_date],
      user_ids: params[:user_ids].presence || [],
      context: params[:context].presence,
      agent_ids: params[:agent_ids]&.reject(&:blank?)&.presence,
      lieu_ids: params[:lieu_ids]&.reject(&:blank?) || []
    )
  end
end
