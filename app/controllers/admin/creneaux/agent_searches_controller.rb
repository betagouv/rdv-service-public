# frozen_string_literal: true

class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  def index
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)
    @search_results = search_results

    if @search_results&.count == 1
      skip_policy_scope # TODO: improve pundit checks for creneaux

      redirect_to admin_organisation_slots_path(current_organisation,
                                                helpers.creneaux_search_params(@form).merge(lieu_ids: [@search_results.first.lieu.id])),
                  class: "d-block stretched-link"
    else
      @motifs = policy_scope(Motif).active.ordered_by_name
      @services = policy_scope(Service)
        .where(id: @motifs.pluck(:service_id).uniq)
        .ordered_by_name
      @form.service_id = @services.first.id if @services.count == 1
      @teams = current_organisation.territory.teams
      @agents = policy_scope(Agent)
        .joins(:organisations).where(organisations: { id: current_organisation.id })
        .complete.active.order_by_last_name
      @lieux = policy_scope(Lieu).enabled.ordered_by_name
    end
  end

  private

  def search_results
    return nil unless (params[:commit].present? || request.format.js?) && @form.valid?

    if @form.motif.individuel?
      SearchCreneauxForAgentsService.perform_with(@form)
    else
      SearchRdvCollectifForAgentsService.new(@form).lieu_search
    end
  end
end
