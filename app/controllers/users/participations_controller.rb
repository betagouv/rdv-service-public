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
    @user = User.find(params[:user_id]) if params[:user_id].present?
    @user ||= current_user
    # C'est plus une mise à jour de la participation que vraiment une création
    # d'un point de vue des autorisations
    authorize(@user, :update?)
  end

  def add_participation
    if existing_participation.present? && !existing_participation.excused?
      flash[:notice] = "Usager déjà inscrit pour cet atelier."
      redirect_to users_rdv_path(@rdv, invitation_token: @rdv.rdv_user_token(current_user.id))
    elsif existing_participation.present? && existing_participation.excused?
      existing_participation.change_status_and_notify(current_user, "unknown")
      set_user_name_initials_verified
      flash[:notice] = "Ré-Inscription confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
    else
      rdvs_users = @rdv.rdvs_users.to_a
      rdvs_users.reject! { |rdv_user| rdv_user.user_id.in? current_user.self_and_relatives.map(&:id) }
      rdvs_users << RdvsUser.new(rdv: @rdv, user: @user)
      @rdv.update_and_notify(current_user, rdvs_users: rdvs_users)
      set_user_name_initials_verified
      flash[:notice] = "Inscription confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: @rdv.rdv_user_token(current_user.id))
    end
  end

  def remove_participation
    if existing_participation.nil?
      flash[:notice] = "Cet utilisateur n'est pas inscrit à cet atelier"
      redirect_to users_rdv_path(@rdv, invitation_token: @rdv.rdv_user_token(current_user.id))
    else
      existing_participation.change_status_and_notify(current_user, "excused")
      set_user_name_initials_verified
      flash[:notice] = "Désinscription de l'atelier confirmée"
      redirect_to users_rdv_path(@rdv, invitation_token: existing_participation.rdv_user_token)
    end
  end

  def existing_participation
    @existing_participation ||= @rdv.rdvs_users.find_by(user: @user)
  end
end
