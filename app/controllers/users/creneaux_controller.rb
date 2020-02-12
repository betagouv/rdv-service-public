class Users::CreneauxController < UserAuthController
  before_action :set_creneau_params, only: [:index, :edit, :update]

  def index
    all_creneaux = @rdv.creneaux_available(Date.today..@rdv.starts_at)
    return @creneaux = [] if all_creneaux.empty?

    start_date = params[:date]&.to_date || Date.today
    end_date = [start_date + 6.days, @rdv.starts_at - 1.day].min
    @date_range = (params[:date]&.to_date || all_creneaux.first.starts_at.to_date)..(start_date + 6.days)
    @creneaux = @rdv.creneaux_available(start_date..end_date)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @starts_at = params[:starts_at].to_time
    @creneau = Creneau.new(starts_at: @starts_at, motif: @rdv.motif, lieu_id: @lieu.id)
  end

  def update
    @creneau = Creneau.new(starts_at: params[:starts_at].to_time, motif: @rdv.motif, lieu_id: @lieu.id)
    if @creneau.available?
      @rdv.update(starts_at: @creneau.starts_at)
    else
      redirect_to edit_users_creneaux_path(rdv_id: @rdv.id)
    end
  end

  def set_creneau_params
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
    authorize(@rdv)
    @lieu = Lieu.find_by(address: @rdv.location)
  end
end
