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

  def cancel
    remove_participation
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
    @existing_participation = policy_scope(RdvsUser).where(rdv: @rdv, user: @user.self_and_relatives_and_responsible).first
  end

  def new_participation
    @new_participation ||= RdvsUser.new(rdv: @rdv, user: @user)
  end

  def add_participation
    if existing_participation.present?
      authorize(existing_participation)
      existing_participation.excused? ? change_participation_status : user_is_already_participating
    else
      authorize(new_participation)
      create_participation
    end
  end

  def user_is_already_participating
    flash[:notice] = "Usager déjà inscrit pour cet atelier."
    redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
  end

  def change_participation_status
    # Participation was excused but user is registering again (participation update)
    existing_participation.change_status_and_notify(current_user, "unknown")
    set_user_name_initials_verified
    flash[:notice] = "Ré-Inscription confirmée"
    redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
  end

  def create_participation
    new_participation.create_and_notify(current_user)
    set_user_name_initials_verified
    flash[:notice] = "Inscription confirmée"
    redirect_to users_rdv_path(@rdv, invitation_token: new_participation.rdv_user_token)
  end

  def remove_participation
    if existing_participation.present?
      authorize(existing_participation)
      existing_participation.change_status_and_notify(current_user, "excused")
      set_user_name_initials_verified
      flash[:notice] = "Désinscription de l'atelier confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
    else
      authorize(new_participation)
      flash[:notice] = "Cet utilisateur n'est pas inscrit à cet atelier"
    end
  end
end
