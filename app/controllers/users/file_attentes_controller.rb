class Users::FileAttentesController < UserAuthController
  skip_before_action :authenticate_user!, only: :unsubscribe
  skip_before_action :set_paper_trail_whodunnit, only: :unsubscribe
  skip_after_action :verify_authorized, only: :unsubscribe

  respond_to :js

  # Permet à un utilisateur de se désinscrire de la file d'attente via le lien dans les mails de notification
  # en un seul clique sans avoir à se connecter
  def unsubscribe
    participation = Participation.find_by!(restricted_auth_token: params[:token])
    @file_attente = FileAttente.find_by(rdv: participation.rdv, user: participation.user)
    @file_attente&.destroy!
    render layout: "application_narrow"
  end

  def create_or_delete
    fa = if file_attente_params[:id].present?
           FileAttente.find(file_attente_params[:id])
         else
           FileAttente.where(rdv_id: file_attente_params[:rdv_id], user_id: file_attente_params[:user_id])
             .first_or_initialize
         end

    authorize(fa, policy_class: User::FileAttentePolicy)

    if fa.persisted?
      fa.destroy!
      flash[:alert] = "Vous n'êtes plus sur la liste d'attente"
    else
      fa.save!
      flash[:success] = "Vous êtes à présent sur la liste d'attente"
    end
    redirect_to request.referer.to_s
  end

  private

  def file_attente_params
    params.require(:file_attente).permit(:id, :rdv_id, :user_id)
  end
end
