class Admin::Agenda::RdvsController < Admin::Agenda::BaseController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    # Nous voulons afficher tous les RDVs de l'agent en question.
    # Pour chacun de ces RDVs, nous faisons appel à `Agent::RdvPolicy#show`
    # dans la vue pour déterminer si il faut afficher les infos du RDV ou non.
    skip_authorization
    rdvs = agent.rdvs.includes(:organisation, :lieu, :users, :agents, :participations, motif: [:service])

    rdvs = rdvs.where(starts_at: time_range_params)
    @rdvs = rdvs.map do |rdv|
      if Agent::RdvPolicy.new(current_agent, rdv).show?
        rdv if rdv.not_cancelled? || current_agent.display_cancelled_rdv
      else
        UnauthorizedRdv.new(rdv)
      end
    end.compact
  end

  class UnauthorizedRdv
    def initialize(rdv)
      @rdv = rdv
    end

    delegate :starts_at, :ends_at, to: :@rdv

    def to_partial_path
      "unauthorized_rdv"
    end
  end
end
