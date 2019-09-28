class ProsController < DashboardAuthController
  respond_to :html, :json

  def index
    pros = policy_scope(Pro).order(Arel.sql('LOWER(last_name)')).active
    @complete_pros = pros.complete.includes(:service).page(params[:page])
    @invited_pros = pros.invitation_not_accepted.created_by_invite
  end

  def show
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
    respond_right_bar_with @pro
  end

  def destroy
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
    flash[:notice] = "L'utilisateur a été supprimé" if @pro.soft_delete
    respond_right_bar_with @pro, location: pros_path
  end

  def reinvite
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
    @pro.invite!
    respond_to do |f|
      f.html { redirect_to pros_path, notice: 'Le professionnel a été réinvité' }
      f.js
    end
  end
end
