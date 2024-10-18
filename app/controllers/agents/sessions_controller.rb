class Agents::SessionsController < Devise::SessionsController
  before_action :exclude_signed_in_users, only: [:new]

  def create
    super

    checker = PasswordChecker.new(params[:agent][:password]) # voir aussi app/controllers/users/sessions_controller.rb
    if checker.too_weak?
      flash[:notice] = nil
      flash[:alert] = checker.error_message(current_domain.name)
    end
  end

  def destroy
    if session[:agent_connect_id_token]
      sign_out(:agent) && set_flash_message!(:notice, :signed_out)

      agent_connect_client = AgentConnectOpenIdClient::Logout.new(session.delete(:agent_connect_id_token))

      redirect_to agent_connect_client.agent_connect_logout_url(root_url), allow_other_host: true
    else
      super
    end
  end

  private

  def exclude_signed_in_users
    return true unless user_signed_in?

    redirect_to(
      root_path,
      flash: { error: "Déconnectez-vous d'abord de votre compte usager pour vous connecter en tant qu'agent" }
    )
  end
end
