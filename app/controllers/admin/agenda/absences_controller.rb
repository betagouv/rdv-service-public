class Admin::Agenda::AbsencesController < Admin::Agenda::BaseController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    absences = policy_scope(Absence, policy_scope_class: Agent::AbsencePolicy::Scope).where(agent: agent).includes(agent: :organisations)
    @absence_occurrences = absences.all_occurrences_for(date_range_params)
  end
end
