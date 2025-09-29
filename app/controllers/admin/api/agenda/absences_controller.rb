class Admin::Api::Agenda::AbsencesController < Admin::Api::BaseController
  def index
    @organisation = Organisation.find(params[:organisation_id])

    absences = policy_scope(Absence, policy_scope_class: Agent::AbsencePolicy::Scope).where(agent: params[:agent_id]).includes(agent: :organisations)
    @absence_occurrences = absences.all_occurrences_for(date_range_params)
  end
end
