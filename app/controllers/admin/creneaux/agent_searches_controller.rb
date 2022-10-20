# frozen_string_literal: true

class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  before_action :set_form
  before_action :set_search_results

  helper_method :motif_selected?

  def index
    if motif_selected? && (results_without_lieu? || only_one_lieu?)
      skip_policy_scope # TODO: improve pundit checks for creneaux
      redirect_to admin_organisation_slots_path(current_organisation, creneaux_search_params), class: "d-block stretched-link"
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

  def motif_selected?
    @form.motif.present?
  end

  def only_one_lieu?
    @search_results&.count == 1
  end

  def requires_lieu?
    @form.motif&.requires_lieu?
  end

  def results_without_lieu?
    return false if requires_lieu?

    SearchCreneauxWithoutLieuForAgentsService.perform_with(@form)&.creneaux&.any?
  end

  def set_form
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)
  end

  def set_search_results
    return unless (params[:commit].present? || request.format.js?) && @form.valid?

    @search_results = if @form.motif.individuel?
                        SearchCreneauxForAgentsService.perform_with(@form)
                      else
                        SearchRdvCollectifForAgentsService.new(@form).lieu_search
                      end
  end

  def creneaux_search_params
    creneaux_search_params = helpers.creneaux_search_params(@form)
    if only_one_lieu?
      creneaux_search_params.merge(lieu_ids: [@search_results.first.lieu.id])
    else
      creneaux_search_params
    end
  end
end
