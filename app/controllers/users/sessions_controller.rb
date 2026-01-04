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

    @login_code = LoginCode.new(email: params.dig(:login_code, :email))

    super
  end

  def create
    if auth_options[:scope] == :user && (self.resource = Agent.find_by(email: params[:user]["email"])) && resource.valid_password?(params[:user]["password"])
      return if reset_current_agent_password_if_weak!(params[:user][:password])

      set_flash_message!(:notice, :signed_in)
      sign_in(:agent, resource)

      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      super
    end
  end

  def destroy
    logout_and_redirect_user(flash_message_key: :signed_out)
  end
end
