# frozen_string_literal: true

class Users::ParticipationsController < UserAuthController
  before_action :set_rdv, :set_user

  include TokenInvitable

  def index
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
  end

  def new
    add_participation
  end

  def create
    add_participation
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
    @existing_participation = policy_scope(RdvsUser).find_by(rdv: @rdv, user: @user)
  end

  def add_participation
    # TODO : refacto
    if existing_participation.present?
      authorize(existing_participation)
      if existing_participation.persisted? && !existing_participation.excused?
        # User already participate
        flash[:notice] = "Usager déjà inscrit pour cet atelier."
        redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
      elsif existing_participation.persisted? && existing_participation.excused?
        # Participation was cancelled, user is regsitering again (participation update)
        existing_participation.change_status_and_notify(current_user, "unknown")
        set_user_name_initials_verified
        flash[:notice] = "Ré-Inscription confirmée"
        redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
      end
    else
      participation = RdvsUser.new(rdv: @rdv, user: @user)
      authorize(participation)
      # Empty rdv (only one member by family)
      rdvs_users = @rdv.rdvs_users.to_a
      rdvs_users.reject! { |rdv_user| rdv_user.user_id.in? current_user.self_and_relatives.map(&:id) }
      rdvs_users << participation
      participation.create_and_notify(current_user)
      set_user_name_initials_verified
      flash[:notice] = "Inscription confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: participation.rdv_user_token)
    end
  end
end
