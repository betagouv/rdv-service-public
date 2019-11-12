class Agents::RdvsController < DashboardAuthController
  respond_to :html, :json

  before_action :set_rdv, only: [:show, :edit, :update, :destroy, :status]

  def index
    @rdvs = policy_scope(current_agent.rdvs.where(organisation_id: current_organisation.id)).active.where(starts_at: date_range_params).includes(:motif).order(:starts_at)
  end

  def show
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def edit
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def update
    authorize(@rdv)
    flash[:notice] = 'Le rendez-vous a été modifié.' if @rdv.update(rdv_params)
    respond_right_bar_with @rdv, location: @rdv.agenda_path
  end

  def status
    authorize(@rdv)
    @rdv.update(status_params)
    respond_to do |f|
      f.js
    end
  end

  def destroy
    authorize(@rdv)
    if @rdv.cancel
      flash[:notice] = "Le rendez-vous a été annulé, un message a été envoyé à l'usager."
    else
      flash[:error] = "Une erreur s’est produite, le rendez-vous n’a pas pu être annulé."
      Raven.capture_exception(Exception.new("Deletion failed for rdv : #{@rdv.id}"))
    end
    redirect_to @rdv.agenda_path
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:name, :duration_in_min, :starts_at, agent_ids: [], user_ids: [])
  end

  def status_params
    params.require(:rdv).permit(:status)
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end)
  end
end
