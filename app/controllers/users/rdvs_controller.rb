# frozen_string_literal: true

class Users::RdvsController < UserAuthController
  before_action :verify_user_name_initials, :set_rdv, :set_can_see_rdv_motif, only: %i[show creneaux edit cancel update]
  before_action :set_can_see_rdv_motif, only: %i[show edit index]
  before_action :set_geo_search, only: [:create]
  before_action :set_lieu, only: %i[creneaux edit update]
  before_action :build_creneau, :redirect_if_creneau_not_available, only: %i[edit update]
  after_action :allow_iframe

  include TokenInvitable

  def index
    authorize Rdv
    @rdvs = policy_scope(Rdv).includes(:motif, :rdvs_users, :users).user_with_relatives(current_user.id).for_domain(current_domain)
    @rdvs = params[:past].present? ? @rdvs.past : @rdvs.future
    @rdvs = @rdvs.order(starts_at: :desc).page(params[:page])
  end

  def create
    motif = Motif.find(rdv_params[:motif_id])
    lieu = new_rdv_extra_params[:lieu_id].present? ? Lieu.find(new_rdv_extra_params[:lieu_id]) : nil
    ActiveRecord::Base.transaction do
      @creneau = Users::CreneauSearch.creneau_for(
        user: current_user,
        starts_at: Time.zone.parse(rdv_params[:starts_at]),
        motif: motif,
        lieu: lieu,
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
      notifier = Notifiers::RdvCreated.new(@rdv, current_user)
      notifier.perform
      set_user_name_initials_verified
      if current_domain == Domain::RDV_MAIRIE
        Ants::CreateAppointment.perform_later(rdv: @rdv, user: current_user)
      end
      redirect_to users_rdv_path(@rdv, invitation_token: notifier.rdv_users_tokens_by_user_id[current_user.id]), notice: t(".rdv_confirmed")
    else
      query = {
        address: (new_rdv_extra_params[:address] || new_rdv_extra_params[:where]),
        city_code: new_rdv_extra_params[:city_code], street_ban_id: new_rdv_extra_params[:street_ban_id],
        service: motif.service.id, motif_name_with_location_type: motif.name_with_location_type,
        departement: new_rdv_extra_params[:departement], organisation_ids:  new_rdv_extra_params[:organisation_ids], invitation_token: invitation_token,
      }
      redirect_to prendre_rdv_path(query), flash: { error: t(".creneau_unavailable") }
    end
  end

  def edit; end

  def show; end

  def update
    if @rdv.update(starts_at: @creneau.starts_at, ends_at: @creneau.starts_at + @rdv.duration_in_min.minutes, agent_ids: [@creneau.agent.id])
      notifier = Notifiers::RdvUpdated.new(@rdv, current_user)
      notifier.perform
      flash[:success] = "Votre RDV a bien été modifié"
      redirect_to users_rdv_path(@rdv, invitation_token: notifier.rdv_users_tokens_by_user_id[current_user.id])
    else
      flash[:error] = "Le RDV n'a pas pu être modifié"
      redirect_to creneaux_users_rdv_path(@rdv)
    end
  end

  def cancel
    if @rdv.update_and_notify(current_user, status: "excused")
      flash[:notice] = "Le RDV a bien été annulé."
    else
      flash[:error] = "Impossible d'annuler le RDV."
    end
    redirect_to users_rdv_path(@rdv, invitation_token: @rdv.rdv_user_token(current_user.id))
  end

  def creneaux
    @all_creneaux = @rdv.creneaux_available(Time.zone.today..@rdv.reschedule_max_date)
    return if @all_creneaux.empty?

    start_date = params[:date]&.to_date || @all_creneaux.min.starts_at.to_date
    end_date = [start_date + 6.days, @all_creneaux.max.starts_at.to_date].min
    @date_range = start_date..end_date
    @creneaux = @rdv.creneaux_available(@date_range)
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def build_creneau
    @starts_at = Time.zone.parse(params[:starts_at])
    @creneau = Users::CreneauSearch.creneau_for(
      user: current_user,
      starts_at: @starts_at,
      motif: @rdv.motif,
      lieu: @lieu
    )
  end

  def set_lieu
    @lieu = @rdv.lieu
  end

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:id])
    authorize(@rdv)
  end

  def set_can_see_rdv_motif
    @can_see_rdv_motif = current_user.through_sign_in_form?
  end

  def redirect_if_creneau_not_available
    return if @creneau.present?

    flash[:alert] = "Ce créneau n'est plus disponible"
    redirect_to creneaux_users_rdv_path(@rdv)
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
      lieu_id: creneau.lieu&.id,
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
    params.permit(
      :lieu_id, :motif_name_with_location_type, :departement, :where, :address, :city_code, :street_ban_id,
      :invitation_token, { organisation_ids: [] }
    )
  end

  def rdv_params
    params.permit(:starts_at, :motif_id, :context, user_ids: [])
  end
end
