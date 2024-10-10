class Admin::Agenda::RdvsController < Admin::Agenda::BaseController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    # Nous voulons afficher tous les RDVs de l'agent en question.
    # Pour chacun de ces RDVs, nous faisons appel à `Agent::RdvPolicy#show`
    # dans la vue pour déterminer si il faut afficher les infos du RDV ou non.
    skip_authorization
    @rdvs = agent.rdvs.includes(:organisation, :lieu, :users, :agents, :participations, motif: [:service])

    @rdvs = @rdvs.where(starts_at: time_range_params)
    @rdvs = @rdvs.where(status: Rdv::NOT_CANCELLED_STATUSES) unless current_agent.display_cancelled_rdv
  end
end
