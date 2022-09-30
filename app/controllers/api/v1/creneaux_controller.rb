# frozen_string_literal: true

class Api::V1::CreneauxController < Api::V1::BaseController
  def index
    form = helpers.build_agent_creneaux_search_form(current_organisation, params)
    creneaux = SearchCreneauxForAgentsService.perform_with(form).map(&:creneaux).flatten
    render_collection(MonoPageCollection.new(creneaux, Creneau))
  end
end
