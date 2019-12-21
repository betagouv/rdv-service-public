class Users::RdvsController < UserAuthController
  before_action :set_rdv, only: [:confirmation, :cancel]

  def index
    @rdvs = policy_scope(Rdv).includes(:motif, :rdvs_users, :users)
    @rdvs = params[:past].present? ? @rdvs.past : @rdvs.future
    @rdvs = @rdvs.order(starts_at: :desc).page(params[:page])
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

    @query = { where: @where, service: @motif.service.id, motif: @motif_name, departement: @departement }
    return if @creneau.available?

    flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
    redirect_to lieu_path(@lieu, search: @query)
  end

  def create
    @motif = Motif.find(creneau_params[:motif_id])
    @starts_at = DateTime.parse(creneau_params[:starts_at])
    @creneau = Creneau.new(starts_at: @starts_at, motif: @motif, lieu_id: creneau_params[:lieu_id])
    @user = user_for_rdv
    save_succeeded = false
    ActiveRecord::Base.transaction do
      @rdv = @creneau.to_rdv_for_user(@user)
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
      @query = { where: creneau_params[:where], service: @motif.service.id, motif: @motif.name, departement: creneau_params[:departement] }
      flash[:error] = "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to lieu_path(creneau_params[:lieu_id], search: @query)
    end
  end

  def confirmation
    authorize(@rdv)
  end

  def cancel
    authorize(@rdv)
    if @rdv.cancel
      flash[:notice] = "Le RDV a bien été annulé."
    else
      flash[:error] = "Impossible d'annuler le RDV."
    end
    redirect_to users_rdvs_path
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
  end

  def user_for_rdv
    if creneau_params[:user_ids]
      current_user.available_users_for_rdv.find(creneau_params[:user_ids])
    else
      current_user
    end
  end

  def new_rdv_params
    params.permit(:lieu_id, :motif_name, :starts_at, :departement, :where)
  end

  def creneau_params
    params.require(:rdv).permit(:motif_id, :lieu_id, :starts_at, :departement, :where, :user_ids)
  end
end
