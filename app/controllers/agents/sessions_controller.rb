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

      query_params = {
        id_token_hint: session.delete(:agent_connect_id_token),
        state: SecureRandom.base58(32),
        post_logout_redirect_uri: "http://www.rdv-solidarites.localhost:3000/",
        # post_logout_redirect_uri: "https://#{current_domain.host_name}/#{after_sign_out_path_for(:agent)}",
      }

      agent_connect_logout_url = "#{AGENT_CONNECT_CONFIG.end_session_endpoint}?#{query_params.to_query}"
      redirect_to agent_connect_logout_url, allow_other_host: true
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
