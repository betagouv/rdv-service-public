class Agents::Rdvs::ThirdStepsController < AgentAuthController
  layout 'application-small'

  def new
    skip_authorization
    @rdv = Rdv.new(query_params)
    @rdv.organisation = current_organisation
  end

  def create
    @rdv = Rdv.new(third_step_params)
    @rdv.organisation = current_organisation
    authorize(@rdv)
    if @rdv.save
      redirect_to @rdv.agenda_path_for_agent(current_agent), notice: "Le rendez-vous a été créé."
    else
      render 'new'
    end
  end

  private

  def third_step_params
    params.require(:rdv).permit(:motif_id, :duration_in_min, :starts_at, :location, agent_ids: [], user_ids: [])
  end

  def query_params
    params.permit(:organisation_id, :motif_id, :duration_in_min, :starts_at, :location, agent_ids: [], user_ids: [])
  end
end
