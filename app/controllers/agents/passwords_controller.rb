class Agents::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  def create
    agent = Agent.find_by(email: resource_params[:email])

    if agent
      if agent.complete? && agent.pro_connect_openid_sub.blank? # Les agents qui sont ProConnectés ne peuvent plus se connecter par mot de passe
        agent.send_reset_password_instructions
      elsif agent.invitation_sent_at
        agent.invite!(nil, validate: false)
      end
    end

    flash[:notice] = I18n.t("devise.passwords.send_paranoid_instructions", email: resource_params[:email])
    redirect_to root_path
  end
end
