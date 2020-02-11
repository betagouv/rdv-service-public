class Users::CreneauxController < UserAuthController
  before_action :set_creneau_params, only: [:edit, :update]

  def edit
    @creneau_available = @creneau.available? ? true : false
  end

  def update
    if @creneau.available?
      @rdv.update(starts_at: @starts_at)
    else
      @creneau_available = false
      redirect_to edit_users_creneaux_path(rdv_id: @rdv.id, starts_at: @starts_at)
    end
  end

  def set_creneau_params
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
    authorize(@rdv)
    @starts_at = params[:starts_at].to_time
    lieu = Lieu.find_by(address: @rdv.location)
    @creneau = Creneau.new(starts_at: @starts_at, motif: @rdv.motif, lieu_id: lieu.id)
  end
end
