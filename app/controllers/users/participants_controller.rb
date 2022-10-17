# frozen_string_literal: true

class Users::ParticipantsController < UserAuthController
  def index
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
  end

  def create
    rdv = Rdv.find(params[:rdv_id])
    authorize(rdv)
    user = User.find(params[:user_id])
    if rdv.motif.collectif?
      rdv.users = rdv.users - user.responsible.self_and_relatives_and_responsible
      rdv.users << user
    else
      rdv.users = [user]
    end
    rdv.save
    flash[:notice] = "L'usager #{user.full_name} a été selectionné pour le RDV"
    redirect_to users_rdv_path(rdv)
  end
end
