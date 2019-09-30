class Users::RdvsController < UserAuthController
  def index
    @rdvs = policy_scope(Rdv).includes(:motif).page(params[:page])
  end

  def new
    @motif_name = new_rdv_params[:motif_name]
    @departement = new_rdv_params[:departement]
    @where = new_rdv_params[:where]
    @starts_at = DateTime.parse(new_rdv_params[:starts_at])
    @lieu = Lieu.find(new_rdv_params[:lieu_id])
    @motif = Motif.find_by(organisation_id: @lieu.organisation_id, name: @motif_name)
    @creneau = Creneau.new(starts_at: @starts_at, motif: @motif, lieu_id: @lieu.id)
    @rdv = Rdv.new(starts_at: @starts_at, motif: @motif, users: [current_user])
    authorize(@rdv)

    return if @creneau.available?

    flash[:error] = "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
    redirect_to welcome_motif_path(@departement, @motif_name, where: @where)
  end

  def create
    @motif = Motif.find(creneau_params[:motif_id])
    @starts_at = DateTime.parse(creneau_params[:starts_at])
    @creneau = Creneau.new(starts_at: @starts_at, motif: @motif, lieu_id: creneau_params[:lieu_id])
    save_succeeded = false
    ActiveRecord::Base.transaction do
      @rdv = @creneau.to_rdv_for_user(current_user)
      authorize(@rdv)
      save_succeeded = @rdv.save
    end
    if save_succeeded
      redirect_to users_rdv_confirmation_path(@rdv.id)
    else
      flash[:error] = "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to welcome_motif_path(create_rdv_param[:departement], @motif.name, where: create_rdv_param[:where])
    end
  end

  def confirmation
    @rdv = Rdv.find(params[:rdv_id])
    authorize(@rdv)
  end

  private

  def new_rdv_params
    params.permit(:lieu_id, :motif_name, :starts_at, :departement, :where)
  end

  def creneau_params
    params.require(:rdv).permit(:motif_id, :lieu_id, :starts_at)
  end
end
