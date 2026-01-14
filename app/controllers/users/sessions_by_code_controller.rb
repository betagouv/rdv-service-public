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
    email, code = params.require(:login_code).expect(:email, :code)
    login_service = Users::LoginService.new(
      email:, code:,
      sign_in_user_lambda: ->(user) { sign_in(:user, user) }
    )

    if login_service.perform
      redirect_to after_sign_in_path_for(login_service.user), flash: { success: "Connexion réussie" }
    elsif login_service.should_redirect_to_code_request?
      redirect_to new_users_sessions_by_code_path(email:), flash: { error: login_service.error }
    else
      @existing_login_code = LoginCode.most_recent_usable_for(email: login_service.email)
      @existing_login_code.errors.add(:base, login_service.error)
      render :new
    end
  end

  private

  def storable_location? = false

  def upsert_user(login_code)
    find_and_update_user(login_code) || create_user(login_code)
  end

  def find_and_update_user(login_code)
    user = User.find_by(email: login_code.email)
    return if user.blank?

    if user.first_name != login_code.first_name || user.last_name != login_code.last_name
      user.update!(first_name: login_code.first_name, last_name: login_code.last_name)
    end
    user
  end

  def create_user(login_code)
    user = User.new(
      **login_code.slice(:email, :first_name, :last_name),
      created_through: "auto_through_login"
    )
    user.skip_confirmation_notification!
    user.save!
    user
  end
end
