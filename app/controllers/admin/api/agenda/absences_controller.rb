class Admin::Api::Agenda::AbsencesController < Admin::Api::BaseController
  def index
    agent_ids = Array(params[:agent_ids].presence) + Array(params[:agent_id].presence)
    @organisation = Organisation.find(params[:organisation_id])

    absences = policy_scope(Absence, policy_scope_class: Agent::AbsencePolicy::Scope).where(agent: agent_ids).includes(agent: :organisations)
    @absence_occurrences = absences.all_occurrences_for(date_range_params)
  end
end
