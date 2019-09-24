class Users::RdvsController < UserAuthController
  def index
    @rdvs = policy_scope(Rdv).page(params[:page])
  end
end
