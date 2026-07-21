class Agents::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  def create
    email = resource_params[:email].presence
    redirect_to root_path, flash: { error: "Veuillez saisir une adresse e-mail" } and return unless email

    agent = Agent.find_by(email: email)
    if agent
      UnblockBrevoTransactionalContact.new(email).call

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
