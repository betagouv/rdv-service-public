class Admin::Agenda::AbsencesController < Admin::Agenda::FullCalendarController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    absences = policy_scope_admin(Absence).where(agent: agent).includes(agent: :organisations)
    @absence_occurrences = absences.all_occurrences_for(date_range_params)
  end
end
