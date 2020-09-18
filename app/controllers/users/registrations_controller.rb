class Users::RegistrationsController < Devise::RegistrationsController
  layout :user_devise_layout

  def create
    return invite_and_redirect if User.find_by(email: sign_up_params[:email], confirmed_at: nil)

    super
  end

  def destroy
    authorize([:user, resource])
    resource.soft_delete
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  def pending
    @email_tld = params[:email_tld]
  end

  private

  def build_resource(hash = {})
    self.resource = Users::RegistrationForm.new(hash)
  end

  def user_devise_layout
    user_signed_in? ? "application" : "registration"
  end

  def after_inactive_sign_up_path_for(resource)
    users_pending_registration_path(email_tld: resource.email_tld)
  end

  def invite_and_redirect
    user = User.find_by(email: sign_up_params[:email], confirmed_at: nil)
    user.invite!
    set_flash_message! :notice, :signed_up_but_unconfirmed
    respond_with user, location: after_inactive_sign_up_path_for(user)
  end
end
