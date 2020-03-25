class Agents::Rdvs::SecondStepsController < AgentAuthController
  layout 'application-small'

  def new
    skip_authorization
    rdv = Rdv.new(query_params)
    rdv.agents << current_agent unless query_params[:agent_ids].present?
    @agents_authorize = rdv.motif.service.agents.complete.active.joins(:organisations).where(organisations: { id: current_organisation.id })
    @agents_authorize += current_organisation.agents.complete.active.includes(:service).secretariat if rdv.motif.for_secretariat
    @second_step = Rdv::SecondStep.new(rdv.to_step_params)
    @second_step.starts_at ||= Time.zone.now
    @second_step.duration_in_min ||= @second_step.motif.default_duration_in_min
    @second_step.organisation_id = current_organisation.id
  end

  def create
    build_second_step
    skip_authorization
    if @second_step.valid?
      redirect_to new_organisation_third_step_path(@second_step.to_query)
    else
      render 'new'
    end
  end

  private

  def build_second_step
    rdv = Rdv.new(second_step_params)
    @second_step = Rdv::SecondStep.new(rdv.to_step_params)
    @second_step.organisation_id = current_organisation.id
  end

  def second_step_params
    params.require(:rdv).permit(:motif_id, :duration_in_min, :starts_at, :location, agent_ids: [])
  end

  def query_params
    params.permit(:organisation_id, :motif_id, :duration_in_min, :starts_at, :location, agent_ids: [])
  end
end
