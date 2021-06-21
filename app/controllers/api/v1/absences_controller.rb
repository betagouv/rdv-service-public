# frozen_string_literal: true

class Api::V1::AbsencesController < Api::V1::BaseController
  def index
    absences = policy_scope(Absence)
    absences = absences.where(organisation: current_organisation) if current_organisation.present?
    render_collection(absences.by_starts_at)
  end

  def create
    absence = Absence.new(create_params)
    authorize(absence)
    absence.save!
    render_record absence
  end

  private

  def create_params
    # Allow creating an absence for an agent identified by their email.
    if params[:agent_id].blank? && params[:agent_email].present?
      agent = Agent.find_by!(email: params[:agent_email])
      params[:agent_id] = agent.id
      params.delete(:agent_email)
    end

    params.require(:organisation_id)
    params.permit(:organisation_id, :agent_id, :title, :first_day, :start_time, :end_day, :end_time)
  end
end
