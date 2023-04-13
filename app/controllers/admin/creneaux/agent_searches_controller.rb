# frozen_string_literal: true

class Admin::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  before_action :set_form

  helper_method :motif_selected?

  def index
    # nécessaire pour le `else`
    # et pour le cas où nous sommes sur un
    # motif public_office pour vérifier qu'il n'y
    # qu'un lieu
    set_search_results
    if (params[:commit].present? || request.format.js?) && motif_selected? && (results_without_lieu? || only_one_lieu?)
      skip_policy_scope # TODO: improve pundit checks for creneaux
      redirect_to admin_organisation_slots_path(current_organisation, creneaux_search_params)
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

    search_creneaux_service.present?
  end

  def set_form
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)
  end

  def set_search_results
    return unless (params[:commit].present? || request.format.js?) && @form.valid?

    # Un RDV collectif peut-il avoir lieu à domicile ou au téléphone ?
    @search_results = if @form.motif.individuel?
                        search_creneaux_service
                      else
                        SearchRdvCollectifForAgentsService.new(@form).lieu_search
                      end
  end

  def search_creneaux_service
    @search_creneaux_service ||= if requires_lieu?
                                   SearchCreneauxForAgentsService.perform_with(@form)
                                 else
                                   SearchCreneauxWithoutLieuForAgentsService.perform_with(@form)
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
