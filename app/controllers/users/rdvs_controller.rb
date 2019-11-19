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
      save_succeeded = if @rdv.present?
                         authorize(@rdv)
                         @rdv.save
                       else
                         skip_authorization
                         false
                       end
    end
    if save_succeeded
      redirect_to users_rdv_confirmation_path(@rdv.id)
    else
      flash[:error] = "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to welcome_motif_path(creneau_params[:departement], @motif.name, where: creneau_params[:where])
    end
  end

  def confirmation
    @rdv = Rdv.find(params[:rdv_id])
    authorize(@rdv)
  end

  def cancel
    rdv = Rdv.find(params[:rdv_id])
    authorize(rdv)
    rdv.cancel!
    if rdv.cancelled_at
      flash[:notice] = "Le RDV a bien été annulé."
    else
      flash[:error] = "Impossible d'annuler le RDV."
    end
    redirect_to users_rdvs_path
  end

  private

  def new_rdv_params
    params.permit(:lieu_id, :motif_name, :starts_at, :departement, :where)
  end

  def creneau_params
    params.require(:rdv).permit(:motif_id, :lieu_id, :starts_at, :departement, :where)
  end
end
