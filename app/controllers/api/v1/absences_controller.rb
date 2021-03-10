class Api::V1::AbsencesController < Api::V1::BaseController
  def index
    absences = policy_scope(Absence)
    absences = absences.where(organisation: Organisation.find(params[:organisation_id])) \
      if params[:organisation_id].present?
    render json: AbsenceBlueprint.render(absences.limit(100).all, root: :absences)
  end

  def create
    if params[:organisation_id].blank?
      return render(
        status: :unprocessable_entity,
        json: { success: false, errors: ["organisation_id doit être rempli"] }
      )
    end

    absence = Absence.new(absence_params)
    authorize(absence)
    if absence.save
      render json: AbsenceBlueprint.render(absence, root: :absence)
    else
      render_invalid_resource(absence)
    end
  end

  private

  def absence_params
    params.permit(:organisation_id, :agent_id, :title, :first_day, :start_time, :end_day, :end_time)
  end
end
