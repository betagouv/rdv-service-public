class ProsController < DashboardAuthController
  respond_to :html, :json

  def index
    pros = policy_scope(Pro)
    authorize(pros)
    @complete_pros = pros.includes(:organisation).complete.page(params[:page])
    @invited_pros = pros.includes(:organisation).invitation_not_accepted.created_by_invite
  end

  def show
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
    respond_right_bar_with @pro
  end

  def reinvite
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
    @pro.invite!
    respond_to do |f|
      f.html { redirect_to organisation_pros_path(company), notice: 'L\'utilisateur a été réinvité' }
      f.js
    end
  end
end
