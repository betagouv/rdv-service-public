# frozen_string_literal: true

class Users::RdvsController < UserAuthController
  before_action :set_rdv, only: [:cancel]
  before_action :set_geo_search, only: [:create]
  after_action :allow_iframe
  skip_before_action :authenticate_user!, if: -> { current_user_set? && action_name.in?(%w[show create]) }

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
        lieu: Lieu.find(new_rdv_extra_params[:lieu_id]),
        geo_search: @geo_search
      )
      if @creneau.present?
        @rdv = build_rdv_from_creneau(@creneau)
        authorize(@rdv)
        @save_succeeded = @rdv.save
      end
    end
    skip_authorization if @creneau.nil?
    if @save_succeeded
      Notifiers::RdvCreated.perform_with(@rdv, current_user)
      redirect_to users_rdv_path(@rdv), notice: t(".rdv_confirmed")
    else
      query = { where: new_rdv_extra_params[:where], service: motif.service.id, motif_name_with_location_type: motif.name_with_location_type, departement: new_rdv_extra_params[:departement] }
      redirect_to lieux_path(search: query), flash: { error: t(".creneau_unavailable") }
    end
  end

  def show
    @rdv = Rdv.find(params[:id])
    authorize @rdv
  end

  def cancel
    authorize(@rdv)
    if RdvUpdater.update(current_user, @rdv, { status: "excused" })
      flash[:notice] = "Le RDV a bien été annulé."
    else
      flash[:error] = "Impossible d'annuler le RDV."
    end
    redirect_to users_rdv_path(@rdv)
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
  end

  def set_geo_search
    @geo_search = Users::GeoSearch.new(
      departement: params[:departement],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id].presence
    )
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
    params.permit(:lieu_id, :motif_name_with_location_type, :departement, :where)
  end

  def rdv_params
    params.permit(:starts_at, :motif_id, :context, user_ids: [])
  end
end
