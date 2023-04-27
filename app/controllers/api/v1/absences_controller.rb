# frozen_string_literal: true

class Api::V1::AbsencesController < Api::V1::AgentAuthBaseController
  before_action :retrieve_absence, only: %i[show update destroy]
  def index
    absences = policy_scope(Absence)
    render_collection(absences.by_starts_at)
  end

  def create
    absence = Absence.new(create_params)
    authorize(absence) if absence.valid?
    absence.save!
    render_record absence
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :agent
  end

  def show
    if @absence
      authorize(@absence)
      render_record @absence
    else
      render_error :not_found, not_found: :absence
    end
  end

  def update
    if @absence
      authorize(@absence)
      @absence.update!(update_params)
      render_record @absence
    else
      render_error :not_found, not_found: :absence
    end
  end

  def destroy
    if @absence
      authorize(@absence)
      @absence.destroy!
      head :no_content
    else
      render_error :not_found, not_found: :absence
    end
  end

  private

  def retrieve_absence
    @absence = Absence.find_by(id: params[:id])
  end

  def create_params
    # Allow creating an absence for an agent identified by their email.
    if params[:agent_id].blank? && params[:agent_email].present?
      agent = Agent.find_by!(email: params[:agent_email])
      render_error :not_found, not_found: :agent unless agent
      params[:agent_id] = agent.id
      params.delete(:agent_email)
    end

    params.permit(:agent_id, :title, :first_day, :start_time, :end_day, :end_time)
  end

  def update_params
    params.permit(:title, :first_day, :start_time, :end_day, :end_time)
  end
end
