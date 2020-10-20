class Users::CreneauxController < UserAuthController
  before_action :set_creneau_params, only: [:index, :edit, :update]
  before_action :build_creneau, :redirect_if_creneau_not_available, only: [:edit, :update]

  def index
    @all_creneaux = @rdv.creneaux_available(Date.today..@rdv.starts_at - 1.day)
    return if @all_creneaux.empty?

    start_date = params[:date]&.to_date || @all_creneaux.first.starts_at.to_date
    end_date = [start_date + 6.days, @all_creneaux.last.starts_at.to_date].min
    @date_range = start_date..end_date
    @creneaux = @rdv.creneaux_available(@date_range)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @rdv.update(starts_at: @creneau.starts_at, created_by: :file_attente)
  end

  private

  def set_creneau_params
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
    authorize(@rdv)
    @lieu = @rdv.lieu
  end

  def build_creneau
    @starts_at = params[:starts_at].to_time
    @creneau = Users::CreneauSearch.creneau_for(
      user: current_user,
      starts_at: @starts_at,
      motif: @rdv.motif,
      lieu: Lieu.find(@lieu.id)
    )
  end

  def redirect_if_creneau_not_available
    return if @creneau.present?

    flash[:alert] = "Ce créneau n'est plus disponible"
    redirect_to users_creneaux_index_path(rdv_id: @rdv.id)
  end
end
