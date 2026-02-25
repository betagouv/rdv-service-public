class Users::ParticipationsController < UserAuthController
  before_action :set_rdv, :set_user

  layout "application_narrow"

  include TokenInvitable

  def index
    @rdv = policy_scope(Rdv, policy_scope_class: User::RdvPolicy::Scope).find(params[:rdv_id])
  end

  def create
    if @rdv.motif.organisation.online_booking_only_proconnect? && current_user.pro_connect_openid_sub.blank?
      flash[:error] = "L’inscription a cet événement est réservé aux professionnels. " \
                      "Si vous êtes un professionnel et que vous souhaitez prendre rendez-vous, merci de vous déconnecter et de recommencer votre demande en utilisant ProConnect."
      skip_authorization
      redirect_back fallback_location: root_path and return
    end

    add_participation
  end

  def cancel
    authorize(existing_participation, policy_class: User::ParticipationPolicy)
    change_participation_status("excused")
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:rdv_id])
  end

  def set_user
    @user = if params[:user_id].present?
              User.find(params[:user_id])
            else
              current_user
            end
  end

  def existing_participation
    @existing_participation ||= policy_scope(Participation, policy_scope_class: User::ParticipationPolicy::Scope).where(rdv: @rdv, user: @user.self_and_relatives_and_responsible).first
  end

  def new_participation
    @new_participation ||= Participation.new(rdv: @rdv, user: @user, created_by: current_user)
  end

  def add_participation
    if existing_participation.present?
      authorize(existing_participation, policy_class: User::ParticipationPolicy)
      if existing_participation.excused?
        change_participation_status("unknown")
      else
        participation_changed? ? create_participation : user_is_already_participating
      end
    else
      authorize(new_participation, policy_class: User::ParticipationPolicy)
      create_participation
    end
  end

  def user_is_already_participating
    flash[:notice] = "Usager déjà inscrit"
    redirect_to users_rdv_path(@rdv)
  end

  def change_participation_status(status)
    if status == "unknown" && !@rdv.remaining_seats?
      flash[:alert] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      return redirect_to prendre_rdv_path(motif_name_with_location_type: @rdv.motif.name_with_location_type, lieu_id: @rdv.lieu.id, departement: @rdv.organisation.territory.departement_number)
    end
    existing_participation.change_status_and_notify(current_user, status)
    set_user_name_initials_verified
    flash[:success] = "Participation confirmée" if existing_participation.status == "unknown"
    flash[:notice] = "Participation annulée" if existing_participation.status == "excused"
    redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.restricted_auth_token)
  end

  def create_participation
    unless responsible_or_relatives_participating? || @rdv.collectif?
      raise Pundit::NotAuthorizedError
    end

    unless @rdv.remaining_seats?
      flash[:alert] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      return redirect_to prendre_rdv_path(motif_name_with_location_type: @rdv.motif.name_with_location_type, lieu_id: @rdv.lieu.id, departement: @rdv.organisation.territory.departement_number)
    end
    new_participation.create_and_notify!(current_user)
    set_user_name_initials_verified
    flash[:success] = "Participation confirmée"
    redirect_to users_rdv_path(@rdv, invitation_token: new_participation.restricted_auth_token)
  end

  def responsible_or_relatives_participating?
    @rdv.participations.where(user: current_user.self_and_relatives_and_responsible).any?
  end

  def participation_changed?
    new_participation.user != existing_participation&.user
  end
end
