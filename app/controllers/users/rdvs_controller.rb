class Users::RdvsController < UserAuthController
  before_action :set_rdv, only: [:cancel]

  def index
    @rdvs = policy_scope(Rdv).includes(:motif, :rdvs_users, :users)
    @rdvs = params[:past].present? ? @rdvs.past : @rdvs.future
    @rdvs = @rdvs.order(starts_at: :desc).page(params[:page])
  end

  def create
    motif = Motif.find(rdv_params[:motif_id])
    ActiveRecord::Base.transaction do
      @creneau = Users::CreneauSearch.creneau_for(
        user: current_user,
        starts_at: DateTime.parse(rdv_params[:starts_at]),
        motif: motif,
        lieu: Lieu.find(new_rdv_extra_params[:lieu_id])
      )
      if @creneau.present?
        @rdv = build_rdv_from_creneau(@creneau)
        authorize(@rdv)
        @save_succeeded = @rdv.save
      end
    end
    skip_authorization if @creneau.nil?
    if @save_succeeded
      flash[:notice] = "Votre rendez vous a été confirmé."
      redirect_to authenticated_user_root_path
    else
      query = { where: new_rdv_extra_params[:where], service: motif.service.id, motif_name: motif.name, departement: new_rdv_extra_params[:departement] }
      flash[:error] = "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to lieux_path(search: query)
    end
  end

  def cancel
    authorize(@rdv)
    if @rdv.cancel
      @rdv.file_attentes.destroy_all
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

  def build_rdv_from_creneau(creneau)
    Rdv.new(
      agents: [creneau.agent],
      duration_in_min: creneau.duration_in_min,
      starts_at: creneau.starts_at,
      organisation: creneau.motif.organisation,
      motif: creneau.motif,
      lieu_id: creneau.lieu.id,
      users: [user_for_rdv],
      created_by: :user
    )
  end

  def user_for_rdv
    if rdv_params[:user_ids]
      current_user.available_users_for_rdv.find(rdv_params[:user_ids]).first
    else
      current_user
    end
  end

  def new_rdv_extra_params
    params.permit(:lieu_id, :motif_name, :departement, :where)
  end

  def rdv_params
    params.permit(:starts_at, :motif_id, :context, user_ids: [])
  end
end
