class Agents::Rdvs::ThirdStepsController < AgentAuthController
  layout 'application-small'

  def new
    skip_authorization
    rdv = Rdv.new(query_params)
    @third_step = Rdv::ThirdStep.new(rdv.to_step_params)
    @third_step.organisation_id = current_organisation.id
  end

  def create
    build_third_step
    if @third_step.valid?
      @rdv = @third_step.rdv
      authorize(@rdv)
      @rdv.save
      redirect_to @rdv.agenda_path_for_agent(current_agent), notice: "Le rendez-vous a été créé."
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
    params.permit(:organisation_id, :motif_id, :duration_in_min, :starts_at, :location, agent_ids: [], user_ids: [])
  end
end
