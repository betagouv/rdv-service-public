class Admin::Api::Agenda::AbsencesController < Admin::Api::BaseController
  def index
    @organisation = Organisation.find(params[:organisation_id])

    # Les scopes de policy pour les Absence et les ExternalCalendarEvent délèguent à Agent::AgentPolicy::Scope.
    # Afin d'améliorer les perfs ici, il est préférable de simplement charger les agents via Agent::AgentPolicy::Scope
    # puis de passer cette liste d'agents en WHERE aux requêtes d'Absence et ExternalCalendarEvent.
    agents = Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve.where(id: params[:agent_id]).load

    @absence_occurrences = Absence.where(agent: agents).all_occurrences_for(date_range_params)
  end
end
