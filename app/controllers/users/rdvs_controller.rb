class Users::RdvsController < UserAuthController
  def index
    @rdvs = policy_scope(Rdv)
  end
end
