class Agents::RdvWizard::BaseController < AgentAuthController
  layout 'application-small'

  protected

  def rdv_params
    params
      .require(:rdv)
      .permit(
        :motif_id, :duration_in_min, :starts_at, :location, :notes,
        agent_ids: [], user_ids: []
      )
  end

  def query_params
    params
      .permit(
        :organisation_id,
        :motif_id, :duration_in_min, :starts_at, :location,
        agent_ids: [], user_ids: []
      )
  end
end
