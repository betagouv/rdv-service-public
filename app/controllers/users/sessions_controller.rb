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
    found_agent = Agent.find_by(email: params[:user]["email"])
    if found_agent&.valid_password?(params[:user]["password"])
      self.resource = found_agent
      return if reset_current_agent_password_if_weak!(params[:user][:password])

      sign_in_agent(found_agent)
      return
    end

    found_user = User
      .where(email: params[:user]["email"])
      .joins(:participations)
      .order("participations.created_at DESC")
      .to_a.find { |user| user.valid_password?(params[:user]["password"]) }

    if found_user
      self.resource = found_user
      set_flash_message!(:notice, :signed_in)
      sign_in(:user, found_user)
      respond_with found_user, location: after_sign_in_path_for(found_user)
    else
      super # let Devise handle "not found"
    end
  end

  def destroy
    logout_and_redirect_user(flash_message_key: :signed_out)
  end

  private

  def sign_in_agent(agent)
    set_flash_message!(:notice, :signed_in)
    sign_in(:agent, agent)
    respond_with agent, location: after_sign_in_path_for(agent)
  end
end
