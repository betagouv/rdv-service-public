# frozen_string_literal: true

class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  def index
    @form = build_agent_creneaux_search_form
    @search_results = SearchCreneauxForAgentsService.perform_with(@form) if (params[:commit].present? || request.format.js?) && @form.valid?

    if @search_results&.count == 1
      skip_policy_scope # TODO: improve pundit checks for creneaux
      redirect_to admin_organisation_slots_path(current_organisation,
                                                service_id: @form.service_id,
                                                motif_id: @form.motif.id,
                                                from_date: @form.from_date,
                                                agent_ids: @form.agent_ids,
                                                lieu_id: @search_results.first.lieu.id),
                  class: "d-block stretched-link"
    else
      @motifs = policy_scope(Motif).active.ordered_by_name
      @services = policy_scope(Service)
        .where(id: @motifs.pluck(:service_id).uniq)
        .ordered_by_name
      @form.service_id = @services.first.id if @services.count == 1
      @agents = policy_scope(Agent)
        .joins(:organisations).where(organisations: { id: current_organisation.id })
        .complete.active.order_by_last_name
      @lieux = policy_scope(Lieu).enabled.ordered_by_name
    end
  end

  private

  def build_agent_creneaux_search_form
    AgentCreneauxSearchForm.new(
      organisation_id: current_organisation.id,
      service_id: params[:service_id],
      motif_id: params[:motif_id],
      from_date: params[:from_date],
      # Est-ce que nous avons vraiment des cas avec plusieurs usager ?
      user_ids: params[:user_ids].presence || [],
      context: params[:context].presence,
      agent_ids: params[:agent_ids]&.reject(&:blank?)&.presence,
      lieu_ids: params[:lieu_ids]&.reject(&:blank?) || []
    )
  end
end
