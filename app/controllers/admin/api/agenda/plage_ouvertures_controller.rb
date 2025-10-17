class Admin::Api::Agenda::PlageOuverturesController < Admin::Api::BaseController
  def index
    @organisation = Organisation.find(params[:organisation_id])

    # transition de renommage du paramètre "in_background" en "mixed_with_rdvs"
    params[:mixed_with_rdvs] ||= params[:in_background]

    # Lorsque les plages sont affichées parmi des RDVs, nous voulons les afficher
    # en arrière-plan afin d'améliorer la lisibilité.
    # Excepté sur la vue mensuelle, dans laquelle les éléments sont affichés à la suite.
    month_view_detected = date_range_params.to_a.size.between?(28, 45)
    @display_in_background = params[:mixed_with_rdvs] && !month_view_detected

    plage_ouvertures = policy_scope(PlageOuverture, policy_scope_class: Agent::PlageOuverturePolicy::Scope)
      .for_agent(params[:agent_id])
      .includes(:lieu, :organisation)

    @plage_ouverture_occurrences = plage_ouvertures.all_occurrences_for(date_range_params)
  end

  private

  def pundit_user
    current_agent
  end
end
