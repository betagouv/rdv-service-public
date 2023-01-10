# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :user_devise_layout

  include CanHaveRdvWizardContext
  after_action :allow_iframe

  REDIS_CLIENT = Redis.new(url: Rails.configuration.x.redis_url)

  def create
    REDIS_CLIENT.set("user_session_domain:#{sign_up_params[:email]}", current_domain.name, ex: 1.hour.in_seconds)
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
    user_signed_in? ? "application" : "user_registration"
  end

  def after_inactive_sign_up_path_for(resource)
    users_pending_registration_path(email_tld: resource.email_tld)
  end

  def invite_and_redirect
    user = User.find_by(email: sign_up_params[:email], confirmed_at: nil)
    user.invite!(nil, user_params: sign_up_params)
    set_flash_message! :notice, :signed_up_but_unconfirmed
    respond_with user, location: after_inactive_sign_up_path_for(user)
  end
end
