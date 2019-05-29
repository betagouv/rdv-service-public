class ProsController < DashboardAuthController
  respond_to :html, :json

  def show
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
    respond_right_bar_with @pro
  end
end
