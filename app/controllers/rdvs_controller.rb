class RdvsController < DashboardAuthController
  respond_to :html, :json

  before_action :set_rdv, only: [:show, :edit, :update, :cancel, :destroy]
  before_action :set_organisation, only: [:new, :create]

  def show
    authorize(@rdv)
  end

  def new
    @rdv = Rdv.new(organisation: @organisation)
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def edit
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def create
    @rdv = Rdv.new(rdv_params)
    @rdv.organisation = @organisation
    authorize(@rdv)

    flash[:notice] = "Rendez-vous créé." if @rdv.save
    respond_right_bar_with @rdv, location: rdv_path(@rdv)
  end

  def update
    authorize(@rdv)
    flash[:notice] = 'Le rendez-vous a été modifié.' if @rdv.update(rdv_params)
    respond_right_bar_with @rdv, location: rdv_path(@rdv)
  end

  def cancel
    authorize(@rdv)
    @rdv.update(cancelled_at: Time.zone.now)
    redirect_to root_path, notice: 'Le rendez-vous a été annulé.'
  end

  def destroy
    authorize(@rdv)
    @rdv.destroy
    redirect_to root_path, notice: 'Le rendez-vous a été supprimé.'
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:name, :duration_in_min, :start_at, :max_users_limit)
  end
end
