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

  def participation
    @participation = policy_scope(RdvsUser).find_by(rdv: @rdv, user: @user)
    @participation ||= RdvsUser.new(rdv: @rdv, user: @user)
  end

  def add_participation
    authorize(participation)
    if participation.persisted? && !participation.excused?
      # User already participate
      flash[:notice] = "Usager déjà inscrit pour cet atelier."
      redirect_to users_rdv_path(@rdv, invitation_token: @rdv.rdv_user_token(current_user.id))
    elsif participation.persisted? && participation.excused?
      # Participation was cancelled, user is regsitering again (participation update)
      participation.change_status_and_notify(current_user, "unknown")
      set_user_name_initials_verified
      flash[:notice] = "Ré-Inscription confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: participation.rdv_user_token)
    else
      # New participation
      @rdv.update_and_notify(current_user, rdvs_users: @rdv.rdvs_users)
      set_user_name_initials_verified
      flash[:notice] = "Inscription confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: @rdv.rdv_user_token(current_user.id))
    end
  end
end
