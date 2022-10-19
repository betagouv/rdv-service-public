# frozen_string_literal: true

class Users::ParticipationsController < UserAuthController
  def index
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
  end

  def create
    rdv = Rdv.find(params[:rdv_id])
    user = User.find(params[:user_id]) if params[:user_id].present?
    user ||= current_user
    # C'est plus une mise à jour de la participation que vraiment une création
    # d'un point de vue des autorisations
    authorize(user, :update?)

    if rdv.users.include?(user.id)
      flash[:notice] = "Usager déjà inscrit pour cet atelier."
      redirect_to users_rdv_path(rdv) and return
    end

    if rdv.motif.collectif?
      rdv.users = rdv.users - current_user.self_and_relatives
      rdv.users << user
    else
      rdv.users = [user]
    end
    rdv.save
 
    flash[:notice] = "Inscription confirmée"
    redirect_to users_rdv_path(rdv)
  end
end
