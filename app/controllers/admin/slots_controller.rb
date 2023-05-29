# frozen_string_literal: true

class Admin::SlotsController < AgentAuthController
  def index
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)

    # Dans ce cadre là, nous n'avons qu'un lieu, et donc une structure en résultat de l'appel à ce service.
    # TODO reprendre le service pour le sortir du format `background_job` et proposer 2 méthodes publiques
    # - une pour construire la liste des lieux
    # - une pour le cas où nous avons déjà un lieu
    # À terme, ça pourrait également être un calcul plus réduit. Dans le cas de la recherche sur plusieurs lieux, nous avons besoin de connaitre la prochaine dispo, pas TOUTES les dispo
    @search_result = search_result

    @motifs = policy_scope(Motif).active.ordered_by_name
    @services = policy_scope(Service)
      .where(id: @motifs.pluck(:service_id).uniq)
      .ordered_by_name
    @form.service_id = @services.first.id if @services.count == 1
    @agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .complete.order_by_last_name
    @lieux = policy_scope(Lieu).enabled.ordered_by_name
  end

  private

  def search_result
    if @form.motif.requires_lieu?
      if @form.motif.individuel?
        SearchCreneauxForAgentsService.perform_with(@form).first
      else
        SearchRdvCollectifForAgentsService.new(@form).slot_search
      end
    else
      SearchCreneauxWithoutLieuForAgentsService.perform_with(@form)
    end
  end
end
