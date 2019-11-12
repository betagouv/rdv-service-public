class Agents::Rdvs::ThirdStepsController < DashboardAuthController
  layout 'application-small'

  def new
    rdv = Rdv.new(query_params)
    @third_step = Rdv::ThirdStep.new(rdv.to_step_params)
    @third_step.organisation_id = current_organisation.id
    authorize(@third_step)
  end

  def create
    build_third_step
    authorize(@third_step)
    if @third_step.valid?
      @rdv = @third_step.rdv
      @rdv.save
      redirect_to @rdv.agenda_path, notice: "Le rendez-vous a été créé."
    else
      render 'new'
    end
  end

  private

  def build_third_step
    rdv = Rdv.new(third_step_params)
    @third_step = Rdv::ThirdStep.new(rdv.to_step_params)
    @third_step.organisation_id = current_organisation.id
  end

  def third_step_params
    params.require(:rdv).permit(:motif_id, :duration_in_min, :starts_at, :location, agent_ids: [], user_ids: [])
  end

  def query_params
    params.permit(:motif_id, :duration_in_min, :starts_at, :location, agent_ids: [], user_ids: [])
  end
end
