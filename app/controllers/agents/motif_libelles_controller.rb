class Agents::MotifLibellesController < AgentAuthController
  skip_after_action :verify_policy_scoped, only: :index

  def index
    if params[:service_id]
      motif_libelles = MotifLibelle.where(service_id: params[:service_id])
      respond_to do |format|
        format.json  { render json: { motif_libelles: motif_libelles } }
      end
    end
  end
end
