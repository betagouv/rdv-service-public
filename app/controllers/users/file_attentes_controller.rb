class Users::FileAttentesController < UserAuthController
  respond_to :js

  def create_or_delete
    skip_authorization
    fa = if file_attente_params[:id].present?
           FileAttente.find(file_attente_params[:id])
         else
           FileAttente.where(rdv_id: file_attente_params[:rdv_id], user_id: file_attente_params[:user_id]).first
         end
    if fa.present?
      fa.destroy!
      flash[:alert] = "Vous n'êtes plus sur la liste d'attente"
    else
      FileAttente.create(rdv_id: file_attente_params[:rdv_id], user_id: file_attente_params[:user_id])
      flash[:success] = "Vous êtes à présent sur la liste d'attente"
    end
    redirect_to request.referer.to_s
  end

  private

  def file_attente_params
    params.require(:file_attente).permit(:id, :rdv_id, :user_id)
  end
end
