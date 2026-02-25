class Users::RegistrationsController < Devise::RegistrationsController
  include CanHaveRdvWizardContext
  include Users::DeviseOrSsoLogout

  before_action :set_rdv_insertion_organisations, only: %i[edit destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

  layout "application"
  layout "application_narrow", only: %i[new create update edit]

  def create
    return send_code_to_existing_unconfirmed_user if existing_unconfirmed_user

    build_resource(sign_up_params)
    if resource.save
      login_code = LoginCode.create!(email: resource.email, domain_id: current_domain.id)
      Users::LoginCodeMailer.with(login_code:).login_code.deliver_later
      redirect_to new_users_sessions_by_code_path(email: resource.email),
                  notice: "Votre compte a été créé. Un code de connexion vous a été envoyé par email."
    else
      render :new
    end
  end

  def destroy
    authorize(resource, policy_class: User::UserPolicy)
    # users from rdv-insertion have to be monitored wether they want it or not, so we don't allow them to destroy themselves
    if @rdv_insertion_organisations.empty?
      resource.soft_delete!
    else
      non_rdv_insertion_organisations.each { |org| resource.soft_delete!(org) }
      resource.delete_credentials_and_access_informations
    end

    logout_and_redirect_user(flash_message_key: :destroyed)
  end

  private

  def set_rdv_insertion_organisations
    @rdv_insertion_organisations = resource.organisations - non_rdv_insertion_organisations
  end

  def non_rdv_insertion_organisations
    @non_rdv_insertion_organisations = resource.organisations.reject { |org| org.verticale == "rdv_insertion" }
  end

  def build_resource(hash = {})
    form = Users::RegistrationForm.new(hash)
    self.resource = form
  end

  def send_code_to_existing_unconfirmed_user
    login_code = LoginCode.create!(email: existing_unconfirmed_user.email, domain_id: current_domain.id)
    Users::LoginCodeMailer.with(login_code:).login_code.deliver_later
    redirect_to new_users_sessions_by_code_path(email: existing_unconfirmed_user.email),
                notice: "Un compte existe déjà pour cet email. Un code de connexion vous a été envoyé."
  end

  def existing_unconfirmed_user
    @existing_unconfirmed_user ||= User.find_by(email: sign_up_params[:email], confirmed_at: nil)
  end
end
