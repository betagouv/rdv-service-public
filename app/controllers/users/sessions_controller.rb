class Users::SessionsController < Devise::SessionsController
  layout "user_registration"

  before_action :exclude_signed_in_agents

  def create
    if auth_options[:scope] == :user && (self.resource = Agent.find_by(email: params[:user]["email"])) && resource.valid_password?(params[:user]["password"])
      set_flash_message!(:notice, :signed_in)
      sign_in(:agent, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      super
    end
  end

  private

  def exclude_signed_in_agents
    return true unless agent_signed_in?

    redirect_to(
      root_path,
      flash: { error: "Déconnectez-vous d'abord de votre compte agent pour vous connecter en tant qu'utilisateur" }
    )
  end
end
