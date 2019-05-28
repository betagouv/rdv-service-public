class ProsController < DashboardAuthController

  def show
    @pro = policy_scope(Pro).find(params[:id])
    authorize(@pro)
  end

end
