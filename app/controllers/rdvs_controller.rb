class RdvsController < DashboardAuthController
  respond_to :html, :json

  before_action :set_rdv, only: [:show, :edit, :update, :destroy, :status]

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
    respond_right_bar_with @rdv, location: authenticated_root_path
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
    if @rdv.destroy
      flash[:notice] = "Le rendez-vous a été annulé, un message a été envoyé à l'usager."
    else
      flash[:error] = "Une erreur s’est produite, le rendez-vous n’a pas pu être annulé."
      Airbrake.notify("Deletion failed for rdv : #{@rdv.id}")
    end
    redirect_to authenticated_root_path
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:name, :duration_in_min, :start_at, :max_users_limit, pro_ids: [])
  end

  def status_params
    params.require(:rdv).permit(:status)
  end
end
