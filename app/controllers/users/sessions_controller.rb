class Users::SessionsController < Devise::SessionsController
  layout "application_narrow"

  include CanHaveRdvWizardContext
  include Admin::WeakPasswordControllerConcern
  include Users::DeviseOrSsoLogout

  def new
    # Le flash d'erreur est trop aggressif pour le cas d'un usager non connecté.
    # Un flash de style info est plus adapté.
    if flash[:alert] == I18n.t("devise.failure.unauthenticated")
      # Il faut utiliser un flash.now pour éviter de réafficher le flash après la connexion si on utilise ProConnect
      flash.now[:notice] = flash[:alert]
      flash[:alert] = nil
    end

    super
  end

  def create
    if User.find_by(email: params[:user]["email"])&.valid_password?(params[:user]["password"])
      super and return
    end

    found_agent = Agent.find_by(email: params[:user]["email"])
    self.resource = found_agent # Nécessaire car le code Devise va se baser sur #resource

    if found_agent&.valid_password?(params[:user]["password"])
      return if reset_current_agent_password_if_weak!(params[:user][:password])

      set_flash_message!(:notice, :signed_in)
      sign_in(:agent, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    # Nous n'avons trouvé ni usager ni agent, on laisse devise gérer l'échec.
    super
  end

  def destroy
    logout_and_redirect_user(flash_message_key: :signed_out)
  end
end
