class Users::SessionsController < Devise::SessionsController
  layout "application_narrow"

  include CanHaveRdvWizardContext
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
  end

  def destroy
    logout_and_redirect_user(flash_message_key: :signed_out)
  end
end
