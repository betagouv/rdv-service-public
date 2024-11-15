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
    if params[:oauth_client_app_id].present? && params[:oauth_client_app_id].in?(session[:oauth_app_ids])
      oauth_app = Doorkeeper::Application.find_by(uid: params[:oauth_client_app_id])
      @oauth_client_app_post_logout_redirect_url = oauth_app.post_logout_redirect_uri
    end

    agent_connect_id_token = session.delete(:agent_connect_id_token)

    sign_out(:agent)

    if @oauth_client_app_post_logout_redirect_url
      session[:post_logout_redirect_url] = @oauth_client_app_post_logout_redirect_url
    else
      set_flash_message!(:notice, :signed_out)
    end

    if agent_connect_id_token
      agent_connect_client = AgentConnectOpenIdClient::Logout.new(agent_connect_id_token)

      redirect_to agent_connect_client.agent_connect_logout_url(root_url), allow_other_host: true
    else
      redirect_to after_sign_out_path_for(:agent)
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
