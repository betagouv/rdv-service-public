class Users::SessionsByCodeController < ApplicationController
  attr_reader :email

  layout "application_narrow"

  include CanHaveRdvWizardContext

  def new
    @email = params[:email]
    return redirect_to(new_user_session_path) if @email.blank?

    @existing_login_code = LoginCode.most_recent_usable_for(email:)
  end

  def create
    permitted_params = params.require(:login_code).permit(:email, :code)
    login_service = Users::LoginService.new(**permitted_params.to_h.symbolize_keys, controller: self)

    if login_service.perform
      redirect_to after_sign_in_path_for(login_service.user), flash: { success: "Connexion réussie" }
    elsif login_service.there_is_an_existing_and_usable_login_code?
      @existing_login_code = LoginCode.most_recent_usable_for(email: login_service.email)
      @existing_login_code.errors.add(:base, login_service.error)
      render :new
    else
      redirect_to new_users_sessions_by_code_path(email:), flash: { error: login_service.error }
    end
  end

  private

  def storable_location? = false
end
