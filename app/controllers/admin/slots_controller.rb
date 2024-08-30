class Admin::SlotsController < AgentAuthController
  def index
    @form = helpers.build_agent_creneaux_search_form(current_organisation, params)

    @search_result = if @form.motif.individuel?
                       CreneauxSearch::ForAgent.new(@form).build_result
                     else
                       CreneauxSearch::RdvCollectifForAgent.new(@form).slot_search
                     end
  end
end
