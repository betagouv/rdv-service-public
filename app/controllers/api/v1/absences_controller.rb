# frozen_string_literal: true

class Api::V1::AbsencesController < Api::V1::BaseController
  def index
    absences = policy_scope(Absence)
    absences = absences.where(organisation: Organisation.find(params[:organisation_id])) \
      if params[:organisation_id].present?
    render json: AbsenceBlueprint.render(absences.by_starts_at.limit(100).all, root: :absences)
  end

  def create
    params.require(:organisation_id)

    absence = Absence.new(absence_params)
    authorize(absence)
    absence.save!
    render json: AbsenceBlueprint.render(absence, root: :absence)
  end

  private

  def absence_params
    params.permit(:organisation_id, :agent_id, :title, :first_day, :start_time, :end_day, :end_time)
  end
end
