# frozen_string_literal: true

class Admin::SlotsController < AgentAuthController
  def index
    @form = build_agent_creneaux_search_form

    # Dans ce cadre là, nous n'avons qu'un lieu, et donc une structure en résultat de l'appel à ce service.
    # TODO reprendre le service pour le sortir du format `background_job` et proposer 2 méthodes publiques
    # - une pour construire la liste des lieux
    # - une pour le cas où nous avons déjà un lieu
    # À terme, ça pourrait également être un calcul plus réduit. Dans le cas de la recherche sur plusieurs lieux, nous avons besoin de connaitre la prochaine dispo, pas TOUTES les dispo
    @search_result = SearchCreneauxForAgentsService.perform_with(@form).first

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

  def build_agent_creneaux_search_form
    AgentCreneauxSearchForm.new(
      organisation_id: current_organisation.id,
      service_id: params[:service_id],
      motif_id: params[:motif_id],
      from_date: params[:from_date],
      user_ids: params[:user_ids].presence || [],
      team_ids: params[:team_ids].presence || [],
      context: params[:context].presence,
      agent_ids: params[:agent_ids]&.reject(&:blank?)&.presence,
      lieu_ids: [params[:lieu_id]] || []
    )
  end
end
