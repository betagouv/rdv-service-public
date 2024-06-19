class Users::RegistrationsController < Devise::RegistrationsController
  include CanHaveRdvWizardContext

  before_action :set_rdv_insertion_organisations, only: %i[edit destroy] # rubocop:disable Rails/LexicallyScopedActionFilter
  after_action :allow_iframe

  layout "application"
  layout "application_narrow", only: %i[new edit pending]

  def create
    return invite_and_redirect(existing_unconfirmed_user) if existing_unconfirmed_user

    super
  end

  def destroy
    authorize([:user, resource])
    # users from rdv-insertion have to be monitored wether they want it or not, so we don't allow them to destroy themselves
    if @rdv_insertion_organisations.empty?
      resource.soft_delete
    else
      non_rdv_insertion_organisations.each { |org| resource.soft_delete(org) }
      resource.delete_credentials_and_access_informations
    end
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  def pending
    @email_tld = params[:email_tld]
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
    form.user.sign_up_domain = current_domain
    self.resource = form
  end

  def after_inactive_sign_up_path_for(resource)
    users_pending_registration_path(email_tld: resource.email_tld)
  end

  def invite_and_redirect(user)
    user.invite!(domain: current_domain, options: { user_params: sign_up_params })
    set_flash_message! :notice, :signed_up_but_unconfirmed
    respond_with user, location: after_inactive_sign_up_path_for(user)
  end

  def existing_unconfirmed_user
    @existing_unconfirmed_user ||= User.find_by(email: sign_up_params[:email], confirmed_at: nil)
  end
end
