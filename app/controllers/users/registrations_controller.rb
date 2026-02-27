class Users::RegistrationsController < Devise::RegistrationsController
  include CanHaveRdvWizardContext
  include Users::DeviseOrSsoLogout

  before_action :set_rdv_insertion_organisations, only: %i[edit destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

  layout "application"
  layout "application_narrow", only: %i[new create update edit]

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


end
