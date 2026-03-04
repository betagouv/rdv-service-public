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
      if @rdv_wizard
        valid_login_code = login_code_validator.valid_login_code
        organisation = @rdv_wizard.motif.organisation
        raise "pas d'orga !?" unless organisation

        # retrouver fiche du motif du RDV
        user = Users::UpsertAndLogin.new(email:, first_name: valid_login_code.first_name, last_name: valid_login_code.last_name, organisation:).user
        sign_in(:user, user)
        redirect_to stored_location_for(user), flash: { success: "Connexion réussie" }
      else
        session[:current_user_email] = email
        redirect_to choix_fiche_usager
      end

    elsif login_code_validator.should_redirect_to_code_request?
      redirect_to new_users_sessions_by_code_path(email:), flash: { error: login_service.error }
    else
      @email = email
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code.errors.add(:base, login_code_validator.error)
      render :new
    end
  end

  private

  def storable_location? = false
end
