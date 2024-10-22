class Admin::Agenda::RdvsController < Admin::Agenda::BaseController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    # Nous voulons afficher tous les RDVs de l'agent en question.
    # La façon dont ils sont affichés sera dictée par leur classe.
    skip_authorization
    rdvs = agent.rdvs.includes(:organisation, :motif, :users, :agents_rdvs, motif: [:service])
    rdvs = rdvs.where(starts_at: time_range_params)

    # preload current agent relations to avoid N+1 queries
    current_agent.roles.load
    current_agent.services.load

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
