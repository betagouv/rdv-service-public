class Users::SessionsController < Devise::SessionsController
  layout "application_narrow"

  include CanHaveRdvWizardContext
  include Admin::WeakPasswordControllerConcern
  include Users::DeviseOrSsoLogout

  def new
    # on supprime le flash « vous devez vous connecter ou vous inscrire pour vous connecter »
    flash[:alert] = nil if flash[:alert] == I18n.t("devise.failure.unauthenticated")

    form_params = params[:login_code_request_form] || {}
    @login_code_request_form = Users::LoginCodeRequestForm.new(
      LoginCode.new(
        email: form_params[:email],
        first_name: form_params[:first_name],
        last_name: form_params[:last_name]
      )
    )

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
