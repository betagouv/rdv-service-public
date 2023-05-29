# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :user_devise_layout

  include CanHaveRdvWizardContext
  after_action :allow_iframe

  def create
    return invite_and_redirect(existing_unconfirmed_user) if existing_unconfirmed_user

    super
  end

  def destroy
    authorize([:user, resource])
    resource.destroy!
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
    form = Users::RegistrationForm.new(hash)
    form.user.sign_up_domain = current_domain
    self.resource = form
  end

  def user_devise_layout
    user_signed_in? ? "application" : "user_registration"
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
