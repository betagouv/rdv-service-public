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
    login_code_validator = Users::LoginCodeValidator.new(email:, code:)

    if login_code_validator.valid?
      valid_login_code = login_code_validator.valid_login_code
      valid_login_code.update!(used_at: Time.zone.now)

      if @rdv_wizard
        organisation = @rdv_wizard.motif.organisation
        raise "pas d'orga !?" unless organisation

        first_name = valid_login_code.first_name
        last_name = valid_login_code.last_name
        login_service = Users::UpsertAndLogin.new(email:, first_name:, last_name:, organisation:)

        login_service.perform
        bypass_sign_in(user, scope: :user)
        redirect_to stored_location_for(user), flash: { success: "Connexion réussie" }
      else
        session[:current_user_email] = email
        redirect_to choix_fiche_usager_users_sessions_by_code_path
      end

    elsif login_code_validator.should_redirect_to_code_request?
      redirect_to new_users_sessions_by_code_path(email:), flash: { error: login_code_validator.error }
    else
      @email = email
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code.errors.add(:base, login_code_validator.error)
      render :new
    end
  end

  def choix_fiche_usager
    if session[:current_user_email].present?
      @fiches_usagers = User.where(email: session[:current_user_email]).or(User.where(notification_email: session[:current_user_email]))
    else
      redirect_to new_user_session_path, flash: { error: "Échec de la connexion" }
    end
  end

  def submit_choix_fiche_usager
    current_user_email = session.delete(:current_user_email)
    chosen_user = User.find(params[:user_id])

    if current_user_email == chosen_user.email_or_notification_email
      bypass_sign_in(chosen_user, scope: :user)
      redirect_to stored_location_for(chosen_user) || users_rdvs_path, flash: { success: "Connexion réussie" }
    else
      redirect_to new_user_session_path, flash: { error: "Échec de la connexion" }
    end
  end

  private

  def storable_location? = false
end
